global _start

%define SYS_exit 60
%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define OFFSET_CAPACITY 3
%define MAX_UINT 255

; 1 byte
; Unsigned integer
; Max 255

; [1, 2, 3, 0, 0xFF, 0x4D]

section .bss
array: resb OFFSET_CAPACITY + 1

section .data
pointer: db 0

section .text
_start:
	mov rdi, 1
	call .append

	; does not append, because 256 overflows 1-byte unsigned integer
	mov rdi, 256
	call .append

	mov rdi, 2
	call .append

	mov rdi, 255
	call .append

	mov rdi, 99
	call .append
.check:
	mov al, [array]
	cmp al, 1
	jne .error
	mov al, [array + 1]
	cmp al, 2
	jne .error
	mov al, [array + 2]
	cmp al, 255
	jne .error
	mov al, [array + 3]
	cmp al, 0
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall
.append:
	cmp byte [pointer], OFFSET_CAPACITY   ; check if array is full
	je .done

	cmp rdi, MAX_UINT                ; check if element overflows 1-byte unsigned integer
	jg .done

	; append element (rdi) to the array and increment the pointer
	mov r8b, [pointer]	
	mov [array + r8], rdi	
	inc byte [pointer]
.done:
	ret
