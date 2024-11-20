global _start

%define SYS_brk 12
%define SYS_exit 60
%define EXIT_SUCCESS 0
%define CAPACITY 3

section .bss
array: resb 1

section .data
pointer: db 0
currentCapacity: db CAPACITY ; capacidade inicial é 3

section .text
_start:
	mov rdi, 0
	mov rax, SYS_brk
	syscall
	mov [array], rax

	mov rdi, rax
	add rdi, CAPACITY
	mov rax, SYS_brk
	syscall

	mov rbx, [array]

	mov r8, 1
	call .append

	mov r8, 2
	call .append

	mov r8, 3
	call .append

	mov r8, 4
	call .append

	mov r8, 5
	call .append

	mov r8, 6
	call .append

	mov r8, 7
	call .append
.exit:
	mov rdi, EXIT_SUCCESS
	mov rax, SYS_exit
	syscall
.append:
	mov r9, [currentCapacity]
	cmp byte [pointer], r9b ; verifica se o array está cheio
	je .resize

	mov sil, byte [pointer]
	mov byte [rbx + rsi], r8b
	inc byte [pointer]
.done:
	ret
.resize:
	mov rdi, 0
	mov rax, SYS_brk
	syscall

	mov rdi, rax
	add rdi, CAPACITY
	mov rax, SYS_brk
	syscall

	mov r10, currentCapacity
	add byte [r10], CAPACITY
	jmp .append
