; 32-bit
section .data
    msg db `Hello, world!\n`

section .text
   global _start     

_start:	            
   ; print("Hello, world")
   ; write(fd, mem_buf, size)
   mov	ebx, 1 ; STDOUT
   mov	ecx, msg
   mov	edx, 14 ; len 14
   mov	eax, 4 ; write
   int	0x80     ; syscall

   ; exit(0)
   mov	eax, 1 ; exit
   mov	ebx, 0 ; 0
   int	0x80     ; syscall
