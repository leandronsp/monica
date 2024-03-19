global _start

; Syscalls constants
%define SYS_futex 240      ; futex
%define SYS_mmap2 192      ; allocate memory into heap
%define SYS_clone 120      ; create thread
%define SYS_socket 359     ; open socket
%define SYS_bind 361       ; bind to open socket
%define SYS_listen 363     ; listen to the socket
%define SYS_accept4 364    ; accept connections to the socket
%define SYS_write 4        ; write
%define SYS_close 6        ; close
%define SYS_exit 1         ; exit
%define SYS_exit_group 252 ; exit

; Misc constants
%define STDOUT 1
%define QUEUE_SIZE 10

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

; Futex constants
%define FUTEX_WAIT 0
%define FUTEX_WAKE 1
%define FUTEX_PRIVATE_FLAG 128

section .data
queue: dd QUEUE_SIZE dup(0) ; initialize array with zero's
front: dd 0 
rear: dd 0 
mutex: dd 1

section .bss
sockfd: resd 1
condvar: resd 1

section .text
listenMsg: db "Listening to the port 3000", 0xA, 0
listenMsgLen: equ $- listenMsg
_start:	            
   call _initialize
   mov edi, 0
.pool:
   mov ebx, _thandle
   call _pthread
   inc edi
   cmp edi, 5
   je .done
   jmp .pool
.done:
   call _socket
   mov [sockfd], eax

   call _bind
   call _listen

   ; print("Listening on the port 3000")
   mov esi, listenMsg
   mov edi, listenMsgLen
   call _print
.accept:
   ; accept4(int fd, struct*, int, int)
   mov ebx, [sockfd]
   mov ecx, 0x0
   mov edx, 0x0
   mov esi, 0x0
   mov eax, SYS_accept4
   int 0x80

   mov edi, eax
   call _enqueue
   jmp .accept

_initialize:
   mov dword [front], 0
   mov dword [rear], 0
   mov dword [mutex], 1
   mov dword [condvar], 0
   ret

_socket:
   ; socket(int family, int type, int proto)
   mov ebx, AF_INET
   mov ecx, SOCK_STREAM
   mov edx, SOCK_PROTOCOL
   mov eax, SYS_socket
   int 0x80
   test eax, eax
   js _error
   ret

_bind:
   ; bind(int fd, struct *str, int strlen)
   push dword SIN_ZERO
   push dword IP_ADDRESS
   push word PORT
   push word AF_INET
   mov ebx, [sockfd] 
   mov edx, 16
   mov ecx, esp
   mov eax, SYS_bind
   int 0x80
   add esp, 12
   test eax, eax
   js _error
   ret

_listen:
   ; listen(int fd, int backlog)
   mov ebx, [sockfd]
   mov ecx, BACKLOG
   mov eax, SYS_listen
   int 0x80
   test eax, eax
   js _error
   ret

_thandle:
.forever:
   mov eax, [rear]
   cmp eax, 0
   je .wait
   call _dequeue
   cmp edi, 0
   je .wait
   jmp .handle_task
.wait:
   mov dword [condvar], condvar
   call _wait_condvar ; wait futex
   jmp .forever
.handle_task:
   push edi
   call _handle
   pop ebp
   jmp .forever

response: db `HTTP/1.1 200 OK\r\nContent-Length: 22\r\n\r\n<h1>Hello, World!</h1>`, 0
responseLen: equ $- response
_handle:
   ; write in the client socket
   push ebp
   mov ebp, esp
   mov ebx, [ebp + 8] ; clientfd
   pop ebp

   mov ecx, response
   mov edx, responseLen
   mov eax, SYS_write
   int 0x80

   ; close the client socket
   mov eax, SYS_close
   int 0x80
   ret

_print:
   mov ebx, STDOUT
   mov ecx, esi
   mov edx, edi
   mov eax, SYS_write
   int 0x80
   ret

error: db "An error occurred", 0
errorLen: equ $- error
_error:
   mov ebx, STDOUT
   mov ecx, error
   mov edx, errorLen
   mov eax, SYS_write
   int 0x80

   ; Terminates all threads
   mov ebx, 1
   mov eax, SYS_exit_group
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

_enqueue:
    call _lock_mutex
    mov ebx, [rear]
    mov dword [queue + ebx * 4], edi ; push into the queue
    inc dword [rear] ; increment the rear pointer
    call _emit_signal
    call _unlock_mutex
    ret

_dequeue:
   call _lock_mutex
   xor ebx, ebx
   xor edi, edi
   xor edx, edx

   lea ecx, [queue] ; load effective address into ecx so we can manipulate the register
   mov ebx, [front] ; pointer into ebx

   cmp ebx, [rear]
   je .empty

   mov edi, dword [ecx + ebx * 4] ; get the 1st element
.shift:
   inc ebx
   mov edx, dword [ecx + ebx * 4] ; load the next element into edx
   cmp edx, 0 ; overflow
   je .return
   mov dword [ecx + (ebx - 1) * 4], edx ; shift the next element into the previous position
   cmp ebx, [rear]
   jle .shift
.return:
   mov dword [ecx + (ebx - 1) * 4], 0 ; empty the last index
   dec dword [rear]
   call _unlock_mutex
   ret
.empty:
   mov edi, 0
   call _unlock_mutex
   ret

_lock_mutex:
   mov eax, 0
   ;lock cmpxchg [mutex], eax
   xchg eax, [mutex]   ; atomically exchange mutex value with 0
   test eax, eax       ; test if mutex was previously unlocked
   jnz .done           ; if mutex was previously unlocked, we have successfully locked it
   pause               ; otherwise, spin and retry
   jmp _lock_mutex
.done:
   ret

_unlock_mutex:
   mov dword [mutex], 1
   ret

_wait_condvar:
   mov ebx, condvar
   cmp dword [ebx], 1
   je .done
   mov ecx, FUTEX_WAIT
   mov edx, 1
   mov esi, -1
   mov eax, SYS_futex
   int 0x80
   test eax, eax
   jz .done
   jmp _error
.done:
   ret

_emit_signal:
   mov ebx, condvar
   mov ecx, FUTEX_WAKE | FUTEX_PRIVATE_FLAG
   mov edx, 0
   mov eax, SYS_futex
   int 0x80
   ret
