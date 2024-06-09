global _start

%define SYS_exit 60
%define SYS_brk 12

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1

; 1 byte for value, 8 bytes for next address, 1 fixed-byte (0xFF)
%define NODE_SIZE 10

section .bss
head: resb 8  ; => 0x403000
result: resb 8

section .text
_start:
	; pointer to the linked list in heap
	call .current_brk
	mov [head], rax

	; node_a.value = 1
	mov r8, 1
	call .insert

	; node_b.value = 2
	; node_a.next = node_b
	mov r8, 2
	mov r9, rdx
	call .insert

	; node_c.value = 42
	; node_b.next = node_c
	mov r8, 42
	mov r9, rdx
	call .insert

	call .traverse

	cmp byte [result], 1
	jne .error
	cmp byte [result + 1], 2
	jne .error
	cmp byte [result + 2], 42
	jne .error

	mov rdi, EXIT_SUCCESS
	jmp .exit
.error:
	mov rdi, EXIT_ERROR
.exit:
	mov rax, SYS_exit
	syscall

; Input
; R8: element (required)
; R9: previous (optional)
;
; Output
; RDX: the allocated node
; 1 byte for value, 8 bytes for next address, 1 fixed-byte (0xFF)
.insert:
	call .allocate_node
	mov byte [rdx + 0], r8b               ; add element
	mov byte [rdx + NODE_SIZE - 1], 0xFF  ; add padding (10h byte)

	test r9, r9
	jz .done_insert                       ; no previous node provided

	mov [r9 + 1], rdx                     ; previous.next = current (memory address)
.done_insert:
	ret

.traverse:
	mov rbx, [head]
	mov rsi, 0
.loop_traverse:
	; get the value of the node
	mov r8b, [rbx]
	mov byte [result + rsi], r8b

	; get the address of the next node
	mov rbx, [rbx + 1]

	cmp rbx, 0
	je .done_traverse

	add rsi, 1
	jmp .loop_traverse
.done_traverse:
	ret
	

.current_brk:
	mov rdi, 0
	mov rax, SYS_brk
	syscall
	ret

.allocate_node:
	call .current_brk
	mov rdx, rax  ; RDX will hold the current break before allocation (before move)

	; allocate more memory
	mov rdi, rax
	add rdi, NODE_SIZE
	mov rax, SYS_brk
	syscall
	ret
