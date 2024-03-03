section .data
    msg db `Hello, world!\n`

section .text
   global _start     
	
_start:	            
   mov	eax, 0x4
   mov	ebx, 0x1
   mov	ecx, msg
   mov	edx, 0xE
   int	0x80        
   mov	eax, 0x1
   mov	ebx, 0x0
   int	0x80       
