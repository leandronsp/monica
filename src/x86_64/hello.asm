section .data
    msg db      `hello, world!\n`

section .text
    global _start

_start:
    mov     rax, 0x1
    mov     rdi, 0x1
    mov     rsi, msg
    mov     rdx, 0xE
    syscall
    mov    rax, 0x3C
    mov    rdi, 0x0
    syscall
