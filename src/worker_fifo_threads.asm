global _start

%define SYS_write 1        
%define SYS_read 0         
%define SYS_open 2         
%define SYS_close 3        
%define SYS_exit 60
%define STDOUT 1
%define EXIT_SUCCESS 0

%define SYS_futex 202
%define SYS_clone 56
%define SYS_brk 12

%define CHILD_STACK_SIZE 4096
%define CLONE_VM 0x00000100
%define CLONE_FS 0x00000200
%define CLONE_FILES 0x00000400
%define CLONE_PARENT 0x00008000
%define CLONE_THREAD 0x00010000
%define CLONE_IO 0x80000000
%define CLONE_SIGHAND 0x00000800
%define QUEUE_OFFSET_CAPACITY 1
%define FUTEX_WAIT 0
%define FUTEX_WAKE 1
%define FUTEX_PRIVATE_FLAG 128

section .data
condvar: dq 0
queuePtr: db 0
queueSize: dq QUEUE_OFFSET_CAPACITY
newline: db 0xA, 0
fifo: db "monica", 0
starting: db "Starting the worker...", 0
doing: db "[Job] Processing ", 0

section .bss
queue: resb 8
fifoFd: resq 1
fifoBuf: resb 1      
fifoBufLen: equ 1    

section .text
_start:
	push starting
	call print
	push rbp

	push newline
	call print
	pop rbp
.initialize_queue:
	mov rdi, 0
	mov rax, SYS_brk
	syscall
	mov [queue], rax

	mov rdi, rax
	add rdi, QUEUE_OFFSET_CAPACITY
	mov rax, SYS_brk
	syscall
.initialize_pool:
	mov r10, 0
.pool:
	call thread        
	inc r10
	cmp r10, 5
	je .wait_fifo
	jmp .pool
.wait_fifo:
	; open FIFO for reading
	mov rdi, fifo
	mov rsi, 0               ; read mode
	mov rdx, 0777            ; read, write and exec by all
	mov rax, SYS_open
	syscall
	mov [fifoFd], rax

	; wait for message from FIFO
	mov rdi, [fifoFd]
	mov rsi, fifoBuf
	mov rdx, fifoBufLen
	mov rax, SYS_read
	syscall

	xor rax, rax
	mov al, [fifoBuf]
	sub al, 48 ; convert ASCII to integer
	mov r8, rax
	call enqueue
	call emit_signal

	; close FIFO for reading
	mov rdi, [fifoFd]
	mov rax, SYS_close
	syscall
	jmp .wait_fifo

thread:
	mov rdi, 0
	mov rax, SYS_brk
	syscall
	mov rdx, rax

	mov rdi, rax
	add rdi, CHILD_STACK_SIZE
	mov rax, SYS_brk
	syscall

	mov rdi, CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_PARENT|CLONE_THREAD|CLONE_IO
	lea rsi, [rdx + CHILD_STACK_SIZE - 8]
	mov qword [rsi], handle
	mov rax, SYS_clone
	syscall
	ret

handle:	
	cmp byte [queuePtr], 0         
	je .wait           

	call dequeue      
	call action

	jmp handle       
.wait:
	call wait_condvar 
	jmp handle       

action:
	mov r8, rax
	push doing
	call print
	pop rax

	add r8, 48 ; convert integer to ASCII
	mov rdi, STDOUT
	lea rsi, [r8]
	mov rdx, 1
	mov rax, SYS_write
	syscall

	push newline
	call print
	pop rax
	ret

print:                   
	push rbp               
	mov rbp, rsp           

	mov rsi, [rbp + 16]     
	mov r9, rsi
	mov rdx, 0
.calculate_size:               
	inc rdx
	inc r9
	cmp byte [r9], 0x00
	jz .done
	jmp .calculate_size
.done:                     
	mov rdi, STDOUT
	mov rax, SYS_write
	syscall
	pop rbp                
	ret                    

enqueue:
	mov r9, [queueSize]
	cmp byte [queuePtr], r9b   ; check if queue is full
	je .resize

	xor rdx, rdx
	mov dl, [queuePtr]	
	mov [queue + rdx], r8	
	inc byte [queuePtr]
.done_enqueue:
	ret
.resize:
	mov r10, r8   ; preserve the RDI (element to be added to array)

	mov rdi, 0
	mov rax, SYS_brk
	syscall

	mov rdi, rax
	add rdi, QUEUE_OFFSET_CAPACITY
	mov rax, SYS_brk
	syscall

	mov r9, [queueSize]
	add r9, QUEUE_OFFSET_CAPACITY
	mov [queueSize], r9

	mov rdi, r10
	jmp enqueue

dequeue:
	xor rax, rax
	xor rsi, rsi

	mov al, [queue]
	mov rcx, 0
.loop_dequeue:
	cmp byte [queuePtr], 0
	je .return_dequeue

	cmp cl, [queuePtr]
	je .done_dequeue

	; shift
	xor r10, r10
	mov r10b, [queue + rcx + 1]
	mov byte [queue + rcx], r10b

	inc rcx
	jmp .loop_dequeue
.done_dequeue:
	dec byte [queuePtr]
.return_dequeue:
	ret

emit_signal:
	mov rdi, condvar
	mov rsi, FUTEX_WAKE | FUTEX_PRIVATE_FLAG  ; the difference is in the FUTEX_WAKE flag
	xor rdx, rdx
	xor r10, r10
	xor r8, r8
	mov rax, SYS_futex
	syscall
	ret

wait_condvar:
	mov rdi, condvar           
	mov rsi, FUTEX_WAIT | FUTEX_PRIVATE_FLAG 
	xor rdx, rdx
	xor r10, r10              
	xor r8, r8               
	mov rax, SYS_futex
	syscall
	ret
