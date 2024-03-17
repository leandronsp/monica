section .data
    inputMsg db `Please enter a number: `
    lenInputMessage equ $ - inputMsg
    displayMsg db `You have entered: ` 
    lenDisplayMsg equ $ - displayMsg

section .bss
   num resb 0x10 ; 16

section .text
   global _start     
	
_start:	            
   mov rax, 0x1 ; write
   mov rdi, 0x1 ; STDOUT
   mov rsi, inputMsg
   mov rdx, lenInputMessage
   syscall

   mov rax, 0x0 ; read
   mov rdi, 0x0 ; STDIN
   mov rsi, num
   mov rdx, 0x10
   syscall

   mov rax, 0x1 ; write
   mov rdi, 0x1 ; STDOUT
   mov rsi, displayMsg
   mov rdx, lenDisplayMsg
   syscall

   mov rax, 0x1 ; write
   mov rdi, 0x1 ; STDOUT
   mov rsi, num
   mov rdx, 0x10
   syscall

   mov rax, 0x3C ; (60) exit
   mov rdi, 0x0 ; 0
   syscall
