global _start

%define SYS_read 0
%define SYS_write 1
%define SYS_exit 60

%define EXIT_SUCCESS 0
%define STDIN 0
%define STDOUT 1

section .bss
input: resb 256    ; Buffer de entrada (input)
output: resb 256   ; Buffer de saída (output)

section .data
prompt: db "Insira a expressão RPN: ", 0xA
promptLen: equ $ - prompt
msgResult: db "Resultado: ", 0
msgResultLen: equ $ - msgResult
newLine: db 0xA, 0

section .text
_start:
	; Prompt de entrada
	mov rdi, STDOUT
	mov rsi, prompt
	mov rdx, promptLen
	mov rax, SYS_write
	syscall

	mov rdi, STDIN
	mov rsi, input
	mov rdx, 256
	mov rax, SYS_read
	syscall

	; Mensagem de saída (resultado)
	mov rdi, STDOUT
	mov rsi, msgResult
	mov rdx, msgResultLen
	mov rax, SYS_write
	syscall

	; Rotina de cálculo RPN
	lea rsi, [input]
	call parseRpn

	; Imprime resultado
	lea rsi, [output]
	add rax, '0'
	mov byte [rsi], al
	mov rdi, STDOUT
	mov rdx, 8
	mov rax, SYS_write
	syscall

	; Imprime newline \n no final
	mov rdi, STDOUT
	mov rsi, newLine
	mov rdx, 1
	mov rax, SYS_write
	syscall
.exit:
	mov rdi, EXIT_SUCCESS
	mov rax, SYS_exit
	syscall

parseRpn:
	mov rdx, 0
.nextToken:
	; move para o próximo token
	mov al, byte [rsi + rdx]

	; ignora espaços
	cmp al, 0x20
	je .skipSpace

	; chegou ao fim?
	cmp al, 0xA
	je .doneParse

	cmp al, '0'
	jl .parseOperator
	cmp al, '9'
	jg .parseOperator

	; converte dígito ASCII para inteiro e empilha
	sub al, '0'
	push rax

	; segue para o próximo token
	inc rdx
	jmp .nextToken
.parseOperator:
	cmp al, '+'
	je .add
	cmp al, '-'
	je .sub
	cmp al, '*'
	je .mul
	cmp al, '/'
	je .div
	; segue para o próximo token
	inc rdx
	jmp .nextToken
.add:
	pop rbx
	pop rax
	add rax, rbx

	; empilha resultado
	push rax
	inc rdx
	jmp .nextToken
.sub:
	pop rbx
	pop rax
	sub rax, rbx

	; empilha resultado
	push rax
	inc rdx
	jmp .nextToken
.mul:
	pop rbx
	pop rax
	imul rax, rbx

	; empilha resultado
	push rax
	inc rdx
	jmp .nextToken
.div:
	pop rbx
	pop rax
	xor rdx, rdx
	div rbx

	; empilha resultado
	push rax
	inc rdx
	jmp .nextToken
.skipSpace:
	inc rdx
	jmp .nextToken
.doneParse:
	pop rax
	ret
