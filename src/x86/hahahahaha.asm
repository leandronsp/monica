%define SYS_mmap2 192
%define SYS_clone 120
%define SYS_wait4 114
%define SYS_write 4
%define SYS_exit 1

%define STDIN 0
%define STDOUT 1

%define STACK_SIZE (4096 * 1024) ; 4MB

%define PROT_READ 0x1
%define PROT_WRITE 0x2

%define MAP_GROWSDOWN 0x100
%define MAP_ANONYMOUS 0x0020
%define MAP_PRIVATE 0x0002

%define CLONE_VM 0x00000100
%define CLONE_FS 0x00000200
%define CLONE_FILES 0x00000400
%define CLONE_SIGHAND 0x00000800
%define CLONE_PARENT 0x00008000
%define CLONE_THREAD 0x00010000
%define CLONE_IO 0x80000000

%define THREAD_FLAGS \
 CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_PARENT|CLONE_THREAD|CLONE_IO

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
   push word 0xB80B ; Port 3000
   push word 0x2 ; AF_INET

   mov ebx, [sockfd] ; fd
   mov edx, 16
   mov ecx, esp
   mov eax, 0x169 ; bind
   int 0x80

   test eax, eax
   js _error

   ; listen(int fd, int backlog)
   mov ebx, [sockfd] ; AF_INET
   mov ecx, 2 ; backlog
   mov eax, 0x16B ; listen
   int 0x80

   mov ebx, 1
   mov ecx, listenMsg
   mov edx, listenMsgLen
   mov eax, 4 ; write
   int 0x80

   loop accept

exit:
   ; exit(0)
   xor ebx, ebx
   mov eax, 1
   int 0x80

accept:
   ; accept4(int fd, struct *str, int len, int addrlen)
   mov ebx, [sockfd] ; fd
   mov ecx, 0
   mov edx, 0
   mov eax, 0x16C ; accept
   int 0x80

   mov [clientfd], eax

   mov ebx, handlefn
   call pthread

   loop accept

handlefn:
   mov ebx, [clientfd]
   mov ecx, response
   mov edx, responseLen
   mov eax, 4 ; write
   int 0x80

   mov ebx, [clientfd]
   mov eax, 6 ; close
   int 0x80
   jmp exit

pthread:
   push ebx

   ; thread stack allocation
   mov ebx, 0
   mov ecx, STACK_SIZE
   mov edx, PROT_WRITE | PROT_READ
   mov esi, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
   mov eax, SYS_mmap2
   int 0x80

   lea ecx, [eax + STACK_SIZE - 8]
   pop dword [ecx]
   mov ebx, THREAD_FLAGS
   mov eax, SYS_clone
   int 0x80
   ret

_error:
   mov ebx, 1
   mov ecx, error
   mov edx, errorLen
   mov eax, 4
   int 0x80

   jmp exit
