section .data
   user1 db "leandro", 0xA
   user1Len equ $- user1
   user2 db "sabrina", 0xA
   user2Len equ $- user2
   filename db "users.txt"

section .bss
   fd_out resb 1
   fd_in resb 1
   buffer resb 1024
   bufferLen equ 1024

section .text
   global _start     
	
_start:	            
    ; create syscall
    mov ebx, filename
    mov ecx, 0777
    mov eax, 8
    int 0x80

    mov [fd_out], eax

    ; write syscall
    ; add some static content to it
    mov ebx, [fd_out]
    mov ecx, user1
    mov edx, user1Len
    mov eax, 4
    int 0x80

    ; write syscall
    ; add more static content to it
    mov ebx, [fd_out]
    mov ecx, user2
    mov edx, user2Len
    mov eax, 4
    int 0x80
    
    ; close file
    mov ebx, [fd_out]
    mov eax, 6
    int 0x80

    ; open for reading syscall
    mov ebx, filename
    mov ecx, 0 ; r
    mov edx, 0777
    mov eax, 5
    int 0x80

    mov [fd_in], eax

    ; read the content from file
    mov ebx, [fd_in]
    mov ecx, buffer
    mov edx, bufferLen
    mov eax, 3
    int 0x80

    ; close file
    mov ebx, [fd_in]
    mov eax, 6
    int 0x80

    ; write syscall
    ; print buffer to STDOUT
    mov ebx, 1
    mov ecx, buffer
    mov edx, bufferLen
    mov eax, 4
    int 0x80

exit:
    xor ebx, ebx 
    mov eax, 1   
    int 0x80     
