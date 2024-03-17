segment .data
   name db "Leandro"

segment .bss
   output resb 16

section .text
   global _start     

_start:	            
   push name ; push the address of name onto the stack
   call print
   jmp exit

print:
   push ebp ; save the current base pointer
   mov ebp, esp ; set up a new base pointer based on the stack pointer

   mov eax, [ebp + 8] ; get the address of the 1st parameter

   mov ebx, [eax] ; dereference the first 4 bytes into ebx (because a x86 register is 32-bit)
   mov ecx, [eax + 4] ; dereference the next 4 bytes into ecx

   mov [output], ebx ; copy the first 4 bytes into the buffer
   mov [output + 4], ecx ; copy the next 4 bytes into the buffer

   pop ebp ; restore stack to the previous base pointer

   mov eax, 4 ; write
   mov ebx, 1         
   mov ecx, output         
   mov edx, 7
   int 0x80

   ret

exit:
   mov eax, 1 ; exit
   mov ebx, 0
   int 0x80
