global _start

%define SYS_write 1        
%define SYS_read 0         
%define SYS_open 2         
%define SYS_close 3        
%define SYS_exit 60

%define STDOUT 1
%define EXIT_SUCCESS 0

section .data
newline: db 0xA, 0
fifo: db "monica", 0
starting: db "Starting the worker...", 0
doing: db "[Job] ", 0

section .bss
fifoFd: resq 1
fifoBuf: resq 1024      
fifoBufLen: equ 1024    

section .text
_start:
	push starting
	call .print
	push rbp

	push newline
	call .print
	pop rbp
.open_file:
	; open FIFO for reading
	mov rdi, fifo
	mov rsi, 0               ; read mode
	mov rdx, 0777            ; read, write and exec by all
	mov rax, SYS_open
	syscall
	mov [fifoFd], rax

.read_file:
	; read the message sent into FIFO
	mov rdi, [fifoFd]
	mov rsi, fifoBuf
	mov rdx, fifoBufLen
	mov rax, SYS_read
	syscall

.print_job:
	push doing
	call .print
	pop rbp

	push fifoBuf
	call .print            
	pop rbp               
	
.close_fd:
	; close FIFO for reading
	mov rdi, [fifoFd]
	mov eax, SYS_close
	syscall
	jmp .open_file

.exit:               
	mov rdi, EXIT_SUCCESS
	mov rax, SYS_exit
	syscall                

.print:                   
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
