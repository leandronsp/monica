global _start

%define SYS_brk 12
%define SYS_exit 60

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define MAX_UINT 255
%define OFFSET_CAPACITY 3
%define BYTE_STEP 1

section .bss
arrayPtr: resb 1

section .data
currentCapacity: db OFFSET_CAPACITY
pointer: db 0

section .text
_start:
.allocate:
        xor rdi, rdi
        mov rax, SYS_brk
        syscall
        mov [arrayPtr], rax

        mov rdi, [arrayPtr]
        add rdi, OFFSET_CAPACITY
        mov rax, SYS_brk
        syscall
.populate:
        mov rbx, [arrayPtr]

	mov rdi, 42
	call .append
	mov rdi, 43
	call .append
	mov rdi, 44
	call .append

	; array[0] == 1
	cmp byte [rbx + 0 * BYTE_STEP], 42
	jne .error
	; array[1] == 43
	cmp byte [rbx + 1 * BYTE_STEP], 43
	jne .error
	; array[2] == 44
	cmp byte [rbx + 2 * BYTE_STEP], 44
	jne .error
	; array[3] == 0 (null)
	cmp byte [rbx + 3 * BYTE_STEP], 0
	jne .error

	; add a new element will resize the array (double the capacity)
	mov rdi, 99
	call .append
	; array[3] == 99
	cmp byte [rbx + 3 * BYTE_STEP], 99
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
	mov r10b, [currentCapacity]
        cmp byte [pointer], r10b  ; check if array is full
        je .resize                     

        cmp rdi, MAX_UINT                   ; check if value in rdi is greater than 255 (1-byte unsigned integer)
        jg .done_append                     

	mov sil, [pointer]                  ; move pointer to the lower bytes of rsi (sil)
	mov [rbx + rsi * 1], rdi          ; add rdi (element) to array

        cmp byte [pointer], OFFSET_CAPACITY  ; check if array is full
        je .done_append

	inc byte [pointer]                  ; update the pointer, step one byte
.done_append:
	ret
.resize:
	mov r8, rdi

        xor rdi, rdi
        mov rax, SYS_brk
        syscall
        mov rdi, rax

        add rdi, OFFSET_CAPACITY
        mov rax, SYS_brk
        syscall

	mov r9, [currentCapacity]
	add r9, OFFSET_CAPACITY
	mov [currentCapacity], r9

	mov rdi, r8
	jmp .append
