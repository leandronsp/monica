global _start

%define SYS_exit 60
%define EXIT_SUCCESS 0
%define EXIT_ERROR 1

; 1 byte
; Unsigned integer
; Max 255

; al => 0000 0001
; rax => 0000 0000 0000 0000 0000 0000 0000 0001

section .data
array: db 1, 2, 3, 0

section .text
_start:
.check:
	mov al, [array]        ; array[0]
	mov bl, [array + 1]    ; array[1]
	mov cl, [array + 2]    ; array[2]
	mov sil, [array + 3]   ; array[3]

	cmp al, 1
	jne .error
	cmp bl, 2
	jne .error
	cmp cl, 3
	jne .error
	cmp sil, 0
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall
