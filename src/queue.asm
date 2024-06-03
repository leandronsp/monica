global _start

%define SYS_exit 60

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define OFFSET_CAPACITY 3
%define MAX_UINT 255

; 1 byte
; Unsigned integer
; Max 255

section .bss
queue: resb OFFSET_CAPACITY + 1

section .data
pointer: db 0

section .text
_start:
	mov rdi, 1
	call .enqueue

	mov rdi, 2
	call .enqueue

	call .dequeue
	cmp rax, 1
	jne .error

	call .dequeue
	cmp rax, 2
	jne .error

	call .dequeue
	cmp rax, 0
	jne .error

	mov rdi, 42
	call .enqueue

	call .dequeue
	cmp rax, 42
	jne .error

	mov rdi, 43
	call .enqueue

	mov rdi, 44
	call .enqueue

	call .dequeue
	cmp rax, 43
	jne .error

	call .dequeue
	cmp rax, 44
	jne .error

	call .dequeue
	cmp rax, 0
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall
.enqueue:
	cmp byte [pointer], OFFSET_CAPACITY   ; check if queue is full
	je .done

	cmp rdi, MAX_UINT                ; check if element overflows 1-byte unsigned integer
	jg .done

	; append element (rdi) to the queue and increment the pointer
	xor r8, r8
	mov r8b, [pointer]	
	mov [queue + r8], rdi	
	inc byte [pointer]
.done:
	ret

.dequeue:
	xor rax, rax
	mov al, [queue]
	mov rsi, 0
.loop_dequeue:
	cmp sil, [pointer]
	je .done_dequeue

	cmp byte [pointer], 0
	je .done_dequeue

	; shift
	xor r10, r10
	mov r10, [queue + rsi + 1]
	mov [queue + rsi], r10

	inc rsi
	dec byte [pointer]
	jmp .loop_dequeue
.done_dequeue:
	ret
