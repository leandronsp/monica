global _start

%define SYS_mmap2 192 ; allocate memory
%define SYS_clone 120 ; create thread
%define SYS_wait4 114 ; wait thread
%define SYS_write 4   ; write
%define SYS_exit 1    ; exit

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

section .bss
output: resb 8

section .text
_start:
   mov ebx, threadfn
   call pthread

   ;mov edx, eax
   ;call wthread

exit:
   xor ebx, ebx
   mov eax, SYS_exit
   int 0x80

;wthread:
;   mov ebx, edx
;   mov ecx, esp
;   mov edx, 0x0
;   mov esi, 0x0
;   mov eax, SYS_wait4
;   int 0x80
;   ret

pthread:
   ; pushes the function pointer (threadfn) onto the stack (esp)
   push ebx

   ; mmap2(addr*, int len, int prot, int flags)
   ; => eax: addr (4MB)
   mov ebx, 0x0
   mov ecx, STACK_SIZE
   mov edx, PROT_WRITE | PROT_READ
   mov esi, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
   mov eax, SYS_mmap2
   int 0x80

   ; clone(int flags, thread_stack*)
   mov ebx, THREAD_FLAGS
   lea ecx, [eax + STACK_SIZE - 8] ; ecx -> 0xffffff (4MB)
   pop dword [ecx] ; pop from esp -> ecx -> function pointer
   mov eax, SYS_clone
   int 0x80
   ret

threadfn:
   mov [output], dword "HEY!"
   mov [output + 4], byte 0xA
   mov ebx, STDOUT
   mov ecx, output
   mov edx, 8
   mov eax, SYS_write
   int 0x80
   jmp exit
