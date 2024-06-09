global _start

%define SYS_mmap 9        
%define SYS_clone 56     
%define SYS_exit 60

%define STACK_SIZE (4096 * 1024) 

%define PROT_READ 0x1
%define PROT_WRITE 0x2
%define MAP_GROWSDOWN 0x100
%define MAP_ANONYMOUS 0x0020     ; No file descriptor involved
%define MAP_PRIVATE 0x0002       ; Do not share across processes

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
age: db 0

section .text
_start:
	call _thread

	mov rdi, 0
	mov rax, SYS_exit
	syscall

_thread:
	mov rdi, _handle
	push rdi

	mov rdi, 0
	mov rsi, STACK_SIZE
	mov rdx, PROT_WRITE | PROT_READ
	mov r10, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
	mov rax, SYS_mmap
	syscall

	mov rdi, THREAD_FLAGS
	lea rsi, [rax + STACK_SIZE - 8]     
	pop qword [rsi]
	mov rax, SYS_clone
	syscall

_handle:
	inc byte [age]
