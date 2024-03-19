global _start

; Syscalls constants
%define SYS_socket 41    ; open socket
%define SYS_bind 49      ; bind to open socket
%define SYS_listen 50    ; listen to the socket
%define SYS_accept4 288  ; accept connections to the socket
%define SYS_mmap 9       ; allocate memory into heap
%define SYS_clone 56     ; create thread
%define SYS_wait4 61     ; wait thread
%define SYS_nanosleep 35 ; sleep thread
%define SYS_write 1      ; write
%define SYS_close 3      ; close
%define SYS_exit 60      ; exit

; Misc constants
%define STDOUT 1

; Socket constants
%define AF_INET 0x2
%define SOCK_STREAM 0x1
%define SOCK_PROTOCOL 0x0
%define SIN_ZERO 0x0
%define IP_ADDRESS 0x0
%define PORT 0xB80B ; 3000:big-endian
%define BACKLOG 0x2

; Threading constants
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
response: db `HTTP/1.1 200 OK\r\nContent-Length: 22\r\n\r\n<h1>Hello, World!</h1>`, 0
responseLen: equ $- response
error: db "An error occurred", 0
errorLen: equ $- error
listenMsg: db "Listening to the port 3000", 0xA, 0
listenMsgLen: equ $- listenMsg
   
section .bss
sockfd: resd 1
clientfd: resd 1

section .text
_start:	            
   xor rdi, rdi
   mov rax, SYS_exit
   syscall

_exit:
   ; exit(0)
   xor rdi, rdi
   mov rax, SYS_exit
   syscall

_socket:
   ; socket(int family, int type, int proto)
   mov rdi, AF_INET
   mov rsi, SOCK_STREAM
   mov rdx, SOCK_PROTOCOL
   mov rax, SYS_socket
   syscall
   test rax, rax
   js _error
   ret

_bind:
   ; bind(int fd, struct *str, int strlen)
   push qword SIN_ZERO
   push qword IP_ADDRESS
   push word PORT
   push word AF_INET
   mov rdi, [sockfd] 
   mov rsi, rsp
   mov rdx, 16
   mov rax, SYS_bind
   syscall
   add rsp, 12
   test rax, rax
   js _error
   ret

_listen:
   ; listen(int fd, int backlog)
   mov rdi, [sockfd]
   mov rsi, BACKLOG
   mov rax, SYS_listen
   syscall
   test rax, rax
   js _error
   ret

_accept:
   ; accept4(int fd, struct*, int, int)
   mov rdi, [sockfd]
   mov rsi, 0x0
   mov rdx, 0x0
   mov r10, 0x0
   mov rax, SYS_accept4
   syscall
   mov [clientfd], rax

   mov rdi, _thandle
   call _pthread

   loop _accept

_thandle:
   call _handle
   jmp _exit

_handle:
   ; write in the client socket
   mov rdi, [clientfd]
   mov rsi, response
   mov rdx, responseLen
   mov rax, SYS_write
   syscall

   ; close the client socket
   mov rdi, [clientfd]
   mov rax, SYS_close
   syscall
   ret

_print:
   mov rdi, STDOUT
   mov rdi, r10
   mov rdx, r8
   mov rax, SYS_write
   syscall
   ret

_error:
   mov rdi, STDOUT
   mov rsi, error
   mov rdx, errorLen
   mov rax, SYS_write
   syscall
   jmp _exit

_pthread:
   ; pushes the function pointer (threadfn) onto the stack (rsp)
   push rdi

   ; mmap2(addr*, int len, int prot, int flags)
   ; => rax: addr (4MB)
   mov rdi, 0x0
   mov rsi, STACK_SIZE
   mov rdx, PROT_WRITE | PROT_READ
   mov r10, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
   mov rax, SYS_mmap
   syscall

   ; clone(int flags, thread_stack*)
   mov rdi, THREAD_FLAGS
   lea rsi, [rax + STACK_SIZE - 8] ; rsi -> 0xffffff (4MB)
   pop qword [rsi] ; pop from rsp -> rsi -> function pointer
   mov rax, SYS_clone
   syscall
   ret
