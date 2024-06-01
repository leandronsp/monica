global _start

%define SYS_brk 12
%define SYS_exit 60

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define MAX_UINT 255
%define ARRAY_CAPACITY 10
%define BYTE_STEP 1

section .bss
array: resb ARRAY_CAPACITY + 1

section .data
pointer: db 0

section .text
_start:
.populate:
        mov byte [pointer], 0
        mov r8, 0
.loop:
        cmp r8, 10
        je .done_loop
        inc r8

        ; append
	mov rdi, r8
	call .append

        ; get
        mov rdi, r8
	sub rdi, 1
	cmp [array + rdi * BYTE_STEP], r8b
	jne .error

        jmp .loop
.done_loop:
        ; trying to append one more element but the array is already full
	mov rdi, 11
	call .append

	; array[11] == 0 (null)
	cmp byte [array + rdi * BYTE_STEP], 0
	jne .error
.overflow:
        mov byte [pointer], 0   ; reset pointer

	; add a valid unsigned 1-byte integer
	mov rdi, 255
	call .append

	; add an invalid unsigned 1-byte integer (overflow)
	mov rdi, 256
	call .append
	; it does not change the current value because it overflows
	; array[0] == 255
	cmp byte [array + 0 * BYTE_STEP], 255
	jne .error

	mov rdi, EXIT_SUCCESS
        jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall

; =======================
; ======= append ========
; =======================
.append:
        cmp byte [pointer], ARRAY_CAPACITY  ; check if array is full
        je .done_append                     

        cmp rdi, MAX_UINT                   ; check if value in rdi is greater than 255 (1-byte unsigned integer)
        jg .done_append                     

	mov sil, [pointer]                  ; move pointer to the lower bytes of rsi (sil)
	mov [array + rsi * 1], rdi          ; add rdi (element) to array

        cmp byte [pointer], ARRAY_CAPACITY  ; check if array is full
        je .done_append

	inc byte [pointer]                  ; update the pointer, step one byte
.done_append:
	ret
