global _start

%define SYS_fork 57
%define SYS_exit 60

section .text
_start:
	mov rax, SYS_fork
	syscall

	mov rdi, 0
	mov rax, SYS_exit
	syscall
