global _start

%define SYS_exit 60

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define OFFSET_CAPACITY 5

; 1 byte
; Unsigned integer
; Max 255

section .bss
queue: resb OFFSET_CAPACITY + 1

section .data
pointer: db 0

section .text
_start:
	; [1]
	mov rdi, 1
	call .rpush

	; [1, 2]
	mov rdi, 2
	call .rpush

	; [2]
	call .lpop
	cmp rax, 1
	jne .error

	; [42, 2]
	mov rdi, 42
	call .lpush

	; [2]
	call .rpop
	cmp rax, 2
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall

; O(1)
.rpush:
	; append element (rdi) to the queue and increment the pointer
	xor r8, r8
	mov r8b, [pointer]	
	mov [queue + r8], rdi	
	inc byte [pointer]
.done:
	ret

; O(1)
.rpop:
	xor rax, rax
	xor r10, r10
	mov r10b, [pointer]
	mov al, [queue + r10 - 1]
	mov byte [queue + r10 - 1], 0

	cmp byte [pointer], 0
	je .done_rpop

	dec byte [pointer]
.done_rpop:
	ret

; O(n)
.lpop:
	xor rax, rax
	mov al, [queue]
	mov rsi, 0
.loop_lpop:
	cmp sil, [pointer]
	je .done_lpop

	cmp byte [pointer], 0
	je .done_lpop

	; shift
	xor r10, r10
	mov r10, [queue + rsi + 1]
	mov [queue + rsi], r10

	inc rsi
	dec byte [pointer]
	jmp .loop_lpop
.done_lpop:
	ret

; O(n)
.lpush:
	mov rsi, 0
.loop_lpush:
	cmp sil, [pointer]
	je .done_lpush

	; shift
	xor r10, r10
	mov r10, [queue + rsi]
	mov [queue + rsi + 1], r10

	inc rsi
	jmp .loop_lpush
.done_lpush:
	mov byte [queue], dil	
	inc byte [pointer]
	ret
