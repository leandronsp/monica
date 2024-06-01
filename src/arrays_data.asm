global _start

%define SYS_exit 60

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define BYTE_STEP 1

section .data
array: db 1, 2, 3, 0

section .text
_start:
	; array[0] == 1
	cmp byte [array + 0 * BYTE_STEP], 1
	jne .error

	; array[1] == 2
	cmp byte [array + 1 * BYTE_STEP], 2
	jne .error

	; array[2] == 3
	cmp byte [array + 2 * BYTE_STEP], 3
	jne .error

	; array[3] == 0 (null)
	cmp byte [array + 3 * BYTE_STEP], 0
	jne .error

        mov rdi, EXIT_SUCCESS
        jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall
