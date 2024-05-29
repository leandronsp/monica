global _start

%define SYS_write 1
%define SYS_exit 60
%define STDOUT 1
%define EXIT_SUCCESS 0

section .data
msg: db "Hello, world!", 0xA
msgLen: equ $ - msg

section .text
_start:
    mov rdi, STDOUT
    mov rsi, msg     
    mov rdx, msgLen 
    mov rax, SYS_write
    syscall

    mov rdi, EXIT_SUCCESS
    mov rax, SYS_exit
    syscall
