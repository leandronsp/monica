SYS_EXIT  equ 1
SYS_READ  equ 3
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1

segment .data
   msg1 db `Enter a digit \n`
   len1 equ $- msg1
   msg2 db `Enter the second digit \n`
   len2 equ $- msg2
   msg3 db `The sum is \n`
   len3 equ $- msg3

segment .bss
   num1 resb 4
   num2 resb 4 
   res resb 4

section .text
   global _start     
	
_start:	            
   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg1         
   mov edx, len1 
   int 0x80

   mov eax, SYS_READ 
   mov ebx, STDIN  
   mov ecx, num1 
   mov edx, 4
   int 0x80

   mov eax, SYS_WRITE        
   mov ebx, STDOUT         
   mov ecx, msg2          
   mov edx, len2         
   int 0x80

   mov eax, SYS_READ  
   mov ebx, STDIN  
   mov ecx, num2 
   mov edx, 4
   int 0x80

   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg3          
   mov edx, len3         
   int 0x80

   ; Terminal: (1, 1)
   mov eax, [num1] ; 49 ascii => 1
   sub eax, '0'	   ; 1 num

   mov ebx, [num2] ; 49 ascii => 1
   sub ebx, '0'    ; 1 num

   add eax, ebx    ; 2 num
   add eax, '0'    ; 2 + 48 = 50 ascii

   mov [res], eax  ; 50 ascii

   mov eax, SYS_WRITE        
   mov ebx, STDOUT
   mov ecx, res         
   mov edx, 1        
   int 0x80

   mov eax, SYS_EXIT   
   mov ebx, 0
   int 0x80
