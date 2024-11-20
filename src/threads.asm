global _start

%define SYS_brk 12
%define SYS_clone 56
%define SYS_write 1        
%define SYS_exit 60

%define STDOUT 1
%define CHILD_STACK_SIZE 4096

%define CLONE_VM 0x00000100
%define CLONE_FS 0x00000200
%define CLONE_FILES 0x00000400
%define CLONE_PARENT 0x00008000
%define CLONE_THREAD 0x00010000
%define CLONE_IO 0x80000000
%define CLONE_SIGHAND 0x00000800

section .data
msg: db "Hello"
msgLen: equ $ - msg

section .text
_start:
	call thread

	mov rdi, 0
	mov rax, SYS_exit
	syscall

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
	mov rdi, STDOUT
	mov rsi, msg
	mov rdx, msgLen
	mov rax, SYS_write
	syscall

	mov rdi, 0
	mov rax, SYS_exit
	syscall
