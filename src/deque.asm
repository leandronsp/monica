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

	; [1, 2, 3]
	mov rdi, 3
	call .rpush

	; [2, 3]
	call .lpop
	cmp rax, 1
	jne .error

	; [3]
	call .lpop
	cmp rax, 2
	jne .error

	; []
	call .lpop
	cmp rax, 3
	jne .error

	; []
	call .rpop
	cmp rax, 0
	jne .error

	; []
	call .lpop
	cmp rax, 0
	jne .error

	; [42]
	mov rdi, 42
	call .lpush

	; [33, 42]
	mov rdi, 33
	call .lpush

	; [22, 33, 42]
	mov rdi, 22
	call .lpush

	; [22, 33]
	call .rpop
	cmp rax, 42
	jne .error

	; [33]
	call .lpop
	cmp rax, 22
	jne .error

	; [33, 99]
	mov rdi, 99
	call .rpush

	; [100, 33, 99]
	mov rdi, 100
	call .lpush

	; [42, 100, 33, 99]
	mov rdi, 42
	call .lpush

	; [42, 100, 33, 99, 22]
	mov rdi, 22
	call .rpush

	; [100, 33, 99, 22]
	call .lpop
	cmp rax, 42
	jne .error

	; [33, 99, 22]
	call .lpop
	cmp rax, 100
	jne .error

	; [33, 99]
	call .rpop
	cmp rax, 22
	jne .error

	; [33]
	call .rpop
	cmp rax, 99
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
	mov r8b, [pointer]	
	mov [queue + r8], rdi	
	inc byte [pointer]
	ret

; O(1)
.rpop:
	mov r8b, [pointer]
	mov al, [queue + r8 - 1]
	mov byte [queue + r8], 0

	cmp byte [pointer], 0
	je .done_rpop
	
	dec byte [pointer]
.done_rpop:
	ret

; O(n)
.lpop:
	xor rax, rax
	xor rsi, rsi

	mov al, [queue]
	mov rcx, 0
.loop_lpop:
	cmp byte [pointer], 0
	je .return_lpop

	cmp cl, [pointer]
	je .done_lpop

	; shift
	xor r10, r10
	mov r10b, [queue + rcx + 1]
	mov byte [queue + rcx], r10b

	inc rcx
	jmp .loop_lpop
.done_lpop:
	dec byte [pointer]
.return_lpop:
	ret

; O(n)
.lpush:
	xor rcx, rcx
	mov cl, [pointer]
.loop_lpush:
	cmp cl, 0
	je .done_lpush

	dec rcx

	; shift
	xor r10, r10
	mov r10b, [queue + rcx]
	mov byte [queue + rcx + 1], r10b

	jmp .loop_lpush
.done_lpush:
	mov byte [queue], dil	
	inc byte [pointer]
	ret
