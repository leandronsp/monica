section .data
   ask db "Number: "
   msg db "Sum: "

section .bss
   number resb 4
   output resb 16
   result resb 4

section .text
   global _start     

_start:	            
   push ask
   call print
   jmp exit

print:
   push rbp 
   mov rbp, rsp 

   mov rax, [rbp + 16] ; memory locatio address
   mov rax, [rax]      ; value in the memory
   mov [output], rax

   pop rbp 

   mov rax, 1 ; write
   mov rdi, 1         
   mov rsi, output         
   mov rdx, 16
   syscall

   ret

exit:
   mov rax, 60 ; exit
   mov rdi, 0
   syscall
