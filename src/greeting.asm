global _start

%define SYS_write 1
%define SYS_exit 60
%define STDOUT 1

section .data
greet: db "Hi, ", 0
newline: db 0xA, 0

section .text
_start:
    push rbp               ; <-- cria um stack frame
    mov rbp, rsp           ; para preservar a pilha

    push greet             ; adiciona "Hi, " na pilha
    call .print            ; chama sub-rotina
    pop rax                ; remove "Hi, " da pilha

    push qword [rbp + 24]  ; adiciona argumento na pilha
    call .print            ; chama sub-rotina
    pop rax                ; remove argumento da pilhha

    push newline           ; adiciona newline na pilha
    call .print            ; chama-subrotina
    pop rax                ; remove newline da pilha

    pop rbp                ; remove RBP da pilha, 
                               ; retornando ao estado original
.exit:               
    mov rdi, 0
    mov rax, SYS_exit
    syscall                ; termina o programa
.print:                   
    push rbp               ; <-- cria um stack frame
    mov rbp, rsp           ; para preservar a pilha

    mov rsi, [rbp + 16]     
    mov r9, rsi
    mov rdx, 0
.calculate_size:               ; loop para calcular tamanho
    inc rdx
    inc r9
    cmp byte [r9], 0x00
    jz .done
    jmp .calculate_size
.done:                     
    mov rdi, STDOUT
    mov rax, SYS_write
    syscall

    pop rbp                ; <--- remove RBP da pilha, 
                               ; retornando ao estado anterior

    ret                    ; <--- retorna fluxo para o
                               ; estado anterior
