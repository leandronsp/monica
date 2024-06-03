global _start

%define SYS_brk 12
%define SYS_exit 60

%define EXIT_SUCCESS 0
%define EXIT_ERROR 1

; 1 byte for value, 8 bytes for next address, 1 fixed-byte (0xFF)
%define NODE_SIZE 10

section .bss
head: resb 8     ; the pointer to the linked list on heap
result: resb 8   ; the result (array) for the traverse subroutine

section .data

section .text
_start:
	; allocate memory for the head
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
.insert:
	call .allocate_node
	mov byte [rdx + 0], r8b               ; add element
	mov byte [rdx + NODE_SIZE - 1], 0xFF  ; add padding (10h byte)

	test r9, r9
	jz .done_insert                       ; no previous node provided

	mov [r9 + 1], rdx                     ; previous.next = current
.done_insert:
	ret

.traverse:
	mov rbx, [head]
	mov rdi, 0
	mov rsi, 0
.loop_traverse:
	; get the value of the node
	mov r8, [rbx + rdi]
	mov byte [result + rsi], r8b

	; get the address of the next node
	lea r8, [rbx + rdi + 1]

	; follow the next node
	mov r8, [r8]

	cmp r8, 0
	je .done_traverse

	add rdi, NODE_SIZE
	add rsi, 1
	jmp .loop_traverse
.done_traverse:
	ret
	
.allocate_node:
	call .current_brk
	mov rdx, rax

	mov rdi, rax
	add rdi, NODE_SIZE
	mov rax, SYS_brk
	syscall
	ret

.current_brk:
	xor rdi, rdi
	mov rax, SYS_brk
	syscall
	ret
