section .data
    msg db `Hello, world!\n`

section .text
   global _start     
	
_start:	            
   mov	eax, 0x4 ; write
   mov	ebx, 0x1 ; STDOUT
   mov	ecx, msg
   mov	edx, 0xE ; len 14
   int	0x80     ; syscall

   mov	eax, 0x1 ; exit
   mov	ebx, 0x0 ; 0
   int	0x80     ; syscall
