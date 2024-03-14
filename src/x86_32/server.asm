section .data
   response db "HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, World!", 0
   responseLen equ $- response
   success db "Okay"
   successLen equ $- success
   error db "Error"
   errorLen equ $- error
   sockaddr:
      .sin_family dw 0x2 ; AF_INET
      .sin_port dw 0xBB8 ; Port 3000
   
; 1 byte => 8 bits
; 1 word => 2 bytes
; 1 dword => 4 bytes
; 1 qword => 8 bytes
section .bss
   sockfd resd 1

section .text
   global _start     
	
_start:	            
   ; socket(int family, int type, int proto)
   mov ebx, 2 ; AF_INET
   mov ecx, 1 ; SOCK_STREAM
   mov edx, 0 ; Default protocol
   mov eax, 167 ; socket
   int 0x80

   mov [sockfd], eax

   ; bind(int fd, struct *str, int strlen)
   mov ebx, [sockfd] ; fd
   mov ecx, sockaddr
   mov edx, 16
   mov eax, 169 ; bind
   int 0x80

   ; listen
   ; loop -> accept

   test eax, eax
   jns _success

   mov ebx, 1
   mov ecx, error
   mov edx, errorLen
   mov eax, 4
   int 0x80

   jmp exit

_success:
   mov ebx, 1
   mov ecx, success
   mov edx, successLen
   mov eax, 4
   int 0x80

exit:
   ; exit(0)
   xor ebx, ebx
   mov eax, 1
   int 0x80
