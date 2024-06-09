global _start

%define SYS_brk 12
%define SYS_clone 56
%define SYS_write 1        
%define SYS_exit 60

%define STDOUT 1
%define CHILD_STACK_SIZE 4096

section .data
counter: db 0
msg: db "Counter:  "
msgLen: equ $ - msg

section .text
_start:
	inc byte [counter]
	call clone

.exit:
	mov rdi, 0
	mov rax, SYS_exit
	syscall

clone:
	mov rdi, 0
	mov rax, SYS_brk
	syscall
	mov rdx, rax

	mov rdi, rax
	add rdi, CHILD_STACK_SIZE
	mov rax, SYS_brk
	syscall

	mov rdi, 0
	lea rsi, [rdx + CHILD_STACK_SIZE - 8]
	mov qword [rsi], handle
	mov rax, SYS_clone
	syscall
	ret

handle:
	mov r9b, [counter]
	lea r8, [msg + msgLen - 1]
	mov byte [r8], r9b

	mov rdi, STDOUT
	mov rsi, msg
	mov rdx, msgLen
	mov rax, SYS_write
	syscall
