global _start

%define SYS_exit 60
%define SYS_brk 12

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define OFFSET_CAPACITY 3
%define MAX_UINT 255

; 1 byte
; Unsigned integer
; Max 255

section .bss
array: resb 1 ;  0x403000

section .data
pointer: db 0
currentCapacity: db OFFSET_CAPACITY

section .text
_start:
	; syscall to get the current program break (0x403000), where the heap starts
	mov rdi, 0
	mov rax, SYS_brk
	syscall
	mov [array], rax

	; syscall to change the program break (0x403003)
	mov rdi, rax
	add rdi, OFFSET_CAPACITY
	mov rax, SYS_brk
	syscall

	mov rbx, [array]    ; store in RBX the pointer of the array in heap

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

	mov rdi, 42
	call .append

	mov rdi, 43
	call .append

	mov rdi, 44
	call .append
.check:
	mov al, [rbx]
	cmp al, 1
	jne .error
	mov al, [rbx + 1]
	cmp al, 2
	jne .error
	mov al, [rbx + 2]
	cmp al, 255
	jne .error
	mov al, [rbx + 3]
	cmp al, 99
	jne .error
	mov al, [rbx + 4]
	cmp al, 42
	jne .error
	mov al, [rbx + 5]
	cmp al, 43
	jne .error
	mov al, [rbx + 6]
	cmp al, 44
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall

.append:
	mov r9, [currentCapacity]
	cmp byte [pointer], r9b   ; check if array is full
	je .resize

	cmp rdi, MAX_UINT                ; check if element overflows 1-byte unsigned integer
	jg .done

	; append element (rdi) to the array and increment the pointer
	mov r8b, [pointer]	
	mov [rbx + r8], rdi	
	inc byte [pointer]
.done:
	ret
.resize:
	mov r10, rdi   ; preserve the RDI (element to be added to array)

	mov rdi, 0
	mov rax, SYS_brk
	syscall

	mov rdi, rax
	add rdi, OFFSET_CAPACITY
	mov rax, SYS_brk
	syscall

	mov r9, [currentCapacity]
	add r9, OFFSET_CAPACITY
	mov [currentCapacity], r9

	mov rdi, r10
	jmp .append
