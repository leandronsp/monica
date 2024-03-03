section .text
    global _start

_start:
    mov     rdx, 1
    inc     rdx
    jmp    int_to_str 


.exit:
    mov     rax, 60
    mov     rdi, 0
    syscall

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
