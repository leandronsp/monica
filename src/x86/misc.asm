section .data
   ask db "Number: "
   askLen equ $- ask
   result db "Sum: "
   resultLen equ $- result

section .rodata
   SYS_WRITE equ 4
   SYS_READ equ 3
   STDIN equ 0
   STDOUT equ 1

section .bss
   output resb 8
   input resb 2
   sum resb 2

section .text
   global _start     
	
_start:	            
   push askLen
   push ask
   call print
   pop ebp
   pop ebp

   call read
   mov edi, [input]

   push askLen
   push ask
   call print
   pop ebp
   pop ebp

   call read
   mov esi, [input]

   ; sum
   sub edi, '0' ; convert ascii to decimal
   sub esi, '0' ; convert ascii to decimal
   add edi, esi ; sum the two registers
   add edi, '0' ; convert result to ascii again
   mov [sum], edi ; move register to the memory buffer
   mov byte [sum + 1], 0xA

   push resultLen
   push result
   call print
   pop ebp
   pop ebp

   push 2
   push sum
   call print
   pop ebp
   pop ebp

   jmp exit

print:
   ; stack frame
   push ebp
   mov ebp, esp
   mov eax, [ebp + 8] ; 1st arg (content)
   mov ebx, [ebp + 12] ; 2nd arg (length)
   pop ebp
   ; stack frame

   mov ecx, eax
   mov edx, ebx
   mov eax, SYS_WRITE 
   mov ebx, STDOUT         
   int 0x80
   ret

read:
   mov eax, SYS_READ 
   mov ebx, STDIN         
   mov ecx, input
   mov edx, 4
   int 0x80
   ret

exit:
   mov eax, 1
   xor ebx, ebx
   int 0x80
