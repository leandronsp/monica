global _start

%define SYS_futex 240
%define SYS_mmap2 192      ; allocate memory into heap
%define SYS_clone 120      ; create thread

%define STACK_SIZE (4096 * 1024) ; 4MB

%define FUTEX_WAIT 0
%define FUTEX_WAKE 1
%define FUTEX_PRIVATE_FLAG 128

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
condvar: dd 1

section .text
_start:	            
   mov ebx, _handle
   call _pthread
   jmp _exit

_handle:
   mov dword [condvar], 1

   mov ebx, condvar
   cmp dword [ebx], 0
   je .done
   mov ecx, FUTEX_WAIT | FUTEX_PRIVATE_FLAG
   mov edx, 1
   xor esi, esi
   xor edi, edi
   mov eax, SYS_futex
   int 0x80

   test eax, eax
   jz .done
   jmp .error
.done:
   ; exit(0)
   mov ebx, 0
   mov eax, 1
   int 0x80
.error:
   ; exit(1)
   mov ebx, 1
   mov eax, 1
   int 0x80

_exit:
   ; exit(0)
   mov ebx, 0
   mov eax, 1
   int 0x80

_pthread:
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
