section .data
    msg db `Displaying 9 stars: \n`
    len equ $ - msg
    star times 0x9 db '*'

section .text
   global _start     
	
_start:	            
   mov	eax, 0x4
   mov	ebx, 0x1
   mov	ecx, msg
   mov	edx, len
   int	0x80        

   mov	eax, 0x4
   mov	ebx, 0x1
   mov	ecx, star
   mov	edx, 0x9
   int	0x80        

   mov	eax, 0x1
   mov	ebx, 0x0
   int	0x80       
