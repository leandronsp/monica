global _start

%define SYS_socket 41
%define SYS_bind 49
%define SYS_listen 50
%define SYS_accept4 288
%define SYS_write 1
%define SYS_close 3
%define SYS_nanosleep 35

%define AF_INET 2
%define SOCK_STREAM 1
%define SOCK_PROTOCOL 0
%define BACKLOG 2
%define CR 0xD
%define LF 0xA

section .data
sockaddr:
	sa_family: dw AF_INET   ; 2 bytes
	port: dw 0xB80B         ; 2 bytes
	ip_addr: dd 0           ; 4 bytes
	sin_zero: dq 0          ; 8 bytes
response: 
	headline: db "HTTP/1.1 200 OK", CR, LF
	content_type: db "Content-Type: text/html", CR, LF
	content_length: db "Content-Length: 22", CR, LF
	crlf: db CR, LF
	body: db "<h1>Hello, World!</h1>"
responseLen: equ $ - response
timespec:
	tv_sec: dq 1
	tv_nsec: dq 0

section .bss
sockfd: resb 1

section .text
_start:
.socket:
	; int socket(int domain, int type, int protocol)
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, SOCK_PROTOCOL
	mov rax, SYS_socket
	syscall
.bind:
	mov [sockfd], rax
	; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
	mov rdi, [sockfd]
	mov rsi, sockaddr
	mov rdx, 16
	mov rax, SYS_bind
	syscall
.listen:
	; int listen(int sockfd, int backlog)
	mov rdi, [sockfd]
	mov rsi, BACKLOG
	mov rax, SYS_listen
	syscall
.accept:
	; int accept(int sockfd, struct *addr, int addrlen, int flags)
	mov rdi, [sockfd]
	mov rsi, 0
	mov rdx, 0
	mov r10, 0
	mov rax, SYS_accept4
	syscall
	mov r8, rax
	call handle
	jmp .accept
handle:
	lea rdi, [timespec]
	mov rax, SYS_nanosleep
	syscall

	; int write(fd)
	mov rdi, r8
	mov rsi, response
	mov rdx, responseLen
	mov rax, SYS_write
	syscall

	; int close(fd)
	mov rdi, r8
	mov rax, SYS_close
	syscall
	ret
