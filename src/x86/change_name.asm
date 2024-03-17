section .data
    name db "Leandro Ali"
    subs db "Adelnor"

section .text
   global _start     
	
_start:	            
   mov eax, [subs]
   mov ebx, [subs+3]
   mov [name], eax
   mov [name+3], ebx

   mov eax, 0x4 ; write
   mov ebx, 0x1 ; STDOUT
   mov ecx, name
   mov edx, 0xB
   int 0x80

   mov eax, 0x1 ; exit
   mov ebx, 0x0 ; 0
   int 0x80       
