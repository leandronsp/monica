section .data
    num1:   equ 100
    num2:   equ 50

section .bss
    sum:    resb 2

section .text
    global _start

_start:
    mov     rax, num1
    mov     rbx, num2
    add     rax, rbx
    mov     [sum], rax
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, 
    mov     rdx, 3
    syscall
    jmp     .exit

int_to_str:
    mov rdx, 0
    mov rbx, 10
    div rbx
    add rdx, 48
    add rdx, 0x0
    push rdx
    inc r12
    cmp rax, 0x0
    jne int_to_str
    jmp print

.exit:
    mov     rax, 60
    mov     rdi, 0
    syscall
