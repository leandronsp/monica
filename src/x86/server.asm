section .data
   response db `HTTP/1.1 200 OK\r\nContent-Length: 22\r\n\r\n<h1>Hello, World!</h1>`, 0
   responseLen equ $- response
   error db "Error", 0
   errorLen equ $- error
   listenMsg db "Listening to the port 3000", 0xA, 0
   listenMsgLen equ $- listenMsg
   
; 1 byte => 8 bits
; 1 word => 2 bytes
; 1 dword => 4 bytes
; 1 qword => 8 bytes
section .bss
   sockfd resd 1
   clientfd resd 1

section .text
   global _start     
	
_start:	            
   ; socket(int family, int type, int proto)
   mov ebx, 2 ; AF_INET
   mov ecx, 1 ; SOCK_STREAM
   mov edx, 0 ; Default protocol
   mov eax, 0x167 ; socket
   int 0x80

   test eax, eax
   js _error

   mov [sockfd], eax

   ; bind(int fd, struct *str, int strlen)
   push dword 0x0 ; sin_zero
   push dword 0x0 ; IP address
   push word 0xB80B ; Port 3000 <<<<<<<---- BUG AQUI, TEM QUE
   push word 0x2 ; AF_INET
   mov ebx, [sockfd] 
   mov edx, 16
   mov ecx, esp
   mov eax, 0x169 
   int 0x80

   test eax, eax
   js _error

   ; listen(int fd, int backlog)
   mov ebx, [sockfd]
   mov ecx, 2
   mov eax, 0x16B
   int 0x80

   ; write "Listening on the port 3000"
   mov ebx, 1
   mov ecx, listenMsg
   mov edx, listenMsgLen
   mov eax, 4
   int 0x80

   loop accept

   jmp exit

exit:
   ; exit(0)
   xor ebx, ebx
   mov eax, 1
   int 0x80

accept:
   ; accept4(int fd, struct*, int, int)
   mov ebx, [sockfd]
   mov ecx, 0x0
   mov edx, 0x0
   mov esi, 0x0
   mov eax, 0x16C
   int 0x80

   mov [clientfd], eax

   ; write in the client socket
   mov ebx, [clientfd]
   mov ecx, response
   mov edx, responseLen
   mov eax, 4
   int 0x80

   ; close the client socket
   mov ebx, [clientfd]
   mov eax, 6
   int 0x80

   loop accept

_error:
   mov ebx, 1
   mov ecx, error
   mov edx, errorLen
   mov eax, 4
   int 0x80
   jmp exit
