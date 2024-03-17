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
   mov eax, 0x4 ; write
   mov ebx, 0x1 ; STDOUT
   mov ecx, inputMsg
   mov edx, lenInputMessage
   int 0x80

   mov eax, 0x3 ; read
   mov ebx, 0x0 ; STDIN
   mov ecx, num
   mov edx, 0x10
   int 0x80

   mov eax, 0x4 ; write
   mov ebx, 0x1 ; STDOUT
   mov ecx, displayMsg
   mov edx, lenDisplayMsg
   int 0x80

   mov eax, 0x4 ; write
   mov ebx, 0x1 ; STDOUT
   mov ecx, num
   mov edx, 0x10
   int 0x80

   mov eax, 0x1 ; exit
   mov ebx, 0x0 ; 0
   int 0x80       
