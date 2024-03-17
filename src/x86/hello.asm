bits 32
global _start

%define SYS_write 4
%define SYS_exit 1
%define STDOUT 1

section .data
msg: db "Hello, world!", 0xA
msgLen: equ $- msg

section .text
_start:	            
   mov ebx, STDOUT
   mov ecx, msg
   mov edx, msgLen
   mov eax, SYS_write
   int 0x80

   xor ebx, ebx
   mov eax, SYS_exit
   int 0x80
