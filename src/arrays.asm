global _start

%define SYS_exit 60
%define EXIT_SUCCESS 0
%define EXIT_ERROR 1

%define ARRAY_CAPACITY 10

section .bss
array: resb ARRAY_CAPACITY

section .data
pointer: db 0

section .text
_start:
	; array << 42
	mov rdi, 42
	call .append
	; array[0] == 42
	mov rdi, 0
	call .get
	cmp rax, 42
	jne .error


	; array << 101
	mov rdi, 101
	call .append
	; array[1] == 101
	mov rdi, 1
	call .get
	cmp rax, 101
	jne .error

	; array << 255
	mov rdi, 255
	call .append
	; array[2] == 255 
	mov rdi, 2
	call .get
	cmp rax, 255
	jne .error

	; array << 256
        ; it overflows and does not append to the array
	mov rdi, 256
	call .append
	; array[3] == 0 (null)
	mov rdi, 3
	call .get
	cmp rax, 0
	jne .error

	; contains(array, 101) == true
	mov rdi, 101
	call .contains
	cmp rax, 1
	jne .error

	; contains(array, 55) == false
	mov rdi, 55
	call .contains
	cmp rax, 0
	jne .error

	; contains(array, 42) == true
	mov rdi, 42
	call .contains
	cmp rax, 1
	jne .error

	; contains(array, 255) == true
	mov rdi, 255
	call .contains
	cmp rax, 1
	jne .error

	; contains(array, 256) == false
	mov rdi, 256
	call .contains
	cmp rax, 0
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit

; =======================
; ======= append ========
; =======================
.append:
        cmp rdi, 255                 ; check if value in rdi is greater than 255 (1-byte unsigned integer)
        jg .done                     ; jump right to `done` if overflow
	mov sil, [pointer]           ; move pointer to the lower bytes of rsi (sil)
	mov [array + rsi * 1], rdi   ; add rdi (element) to array
	inc byte [pointer]           ; update the pointer, step one byte
.done:
	ret

; ====================
; ======= get ========
; ====================
.get:
	mov al, [array + rdi * 1]    ; move element at rdi offset to the lower bytes of rax (al)
	ret

; =========================
; ======= contains ========
; =========================
.contains:
	xor rax, rax                 ; reset rax, return false (0) by default
	mov rsi, 0                   ; start loop counter at the lower rsi (sil)
.loop:
	cmp sil, [pointer]           ; check if loop counter reached the array pointer
	je .done                     ; break loop if checked all the elements
	mov r8b, [array + rsi * 1]   ; move element at rsi to the lower r8 (r8b)
	cmp r8b, dil                 ; check if element at r8b equals to lower dil (rdi)
	je .true                     ; break loop if contains element and return true (1)
	inc sil                      ; increment the loop counter
	jmp .loop                    ; repeat the loop
.true:
	mov al, 1                    ; move 1 to lower rax (al) in case it contains the element
.done:
	ret

; =======================
; ======= .error ========
; =======================
.error:
	mov rdi, EXIT_ERROR
; ======================
; ======= .exit ========
; ======================
.exit:
	mov rax, SYS_exit
	syscall
