segment .data

segment .bss
   number resb 4
   outputBuffer resb 16
   outputLen resb 4

section .text
   global _start     
	
_start:	            
   push 'Enter a number: '
   call print

   push number
   call read

   jmp exit

read:
   push ebp
   mov ebp, esp
   mov eax, [ebp + 8]
   mov [number], eax
   pop ebp

   mov eax, 3
   mov ebx, 0
   mov ecx, number 
   mov edx, 4
   int 0x80
   ret

print:
   push ebp
   mov ebp, esp
   mov eax, [ebp + 8]
   mov ebx, [ebp + 12]

   mov [outputBuffer], eax
   mov [outputLen], ebx

   pop ebp

   mov eax, 4 ; write
   mov ebx, 1         
   mov ecx, outputBuffer
   mov edx, outputLen
   int 0x80
   ret

exit:
   mov eax, 1
   mov ebx, 0
   int 0x80
