global _start

%define SYS_fork 57
%define SYS_write 1        
%define SYS_exit 60

%define STDOUT 1

section .data
msg: db "Hello"
msgLen: equ $ - msg

section .text
_start:
	mov rax, SYS_fork
	syscall

	test rax, rax
	jz handle

	jmp exit

handle:
	mov rdi, STDOUT
	mov rsi, msg
	mov rdx, msgLen
	mov rax, SYS_write
	syscall

exit:
	mov rdi, 0
	mov rax, SYS_exit
	syscall
