; This HTTP server works using a pool of threads.
; When a new connection is established, the client connection (clientfd) is enqueued.
; The queue uses two pointers and employs a mutex and condvar for synchronization.
; Each thread in the pool waits in the queue through a futex until a new connection is enqueued.

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
%define SOCK_STREAM 0x1    ; AF_INET + STREAM = TCP
%define SOCK_PROTOCOL 0x0
%define SIN_ZERO 0x0
%define IP_ADDRESS 0x0     ; 0.0.0.0
%define PORT 0xB80B        ; 3000 (big-endian)
%define BACKLOG 0x2

; Threading constants
%define STACK_SIZE (4096 * 1024) ; 4MB
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

; Futex constants
%define FUTEX_WAIT 0
%define FUTEX_WAKE 1
%define FUTEX_PRIVATE_FLAG 128

section .data
queue: dd QUEUE_SIZE dup(0) ; initialize array with zero's
front: dd 0		    ; the front pointer for connection queue
rear: dd 0		    ; the rear pointer (size) for connection queue
mutex: dd 1                 ; a shared variable to synchronize threads in spinlock
condvar: dd 0               ; a shared variable to synchronize threads in futex

section .bss
sockfd: resd 1 ; the socket file descriptor

section .text
listenMsg: db "Listening to the port 3000", 0xA, 0
listenMsgLen: equ $- listenMsg
; ==========================
; ======== _start ==========
; ==========================
_start:	            
   mov edi, 0           ; thread pool counter
.pool:
   mov ebx, _thandle    ; save the function pointer to be used in the thread
   call _pthread        ; create a new thread
   inc edi
   cmp edi, 5           ; pool size
   je .socket
   jmp .pool
.socket:
   ; open a new socket
   ; socket(int family, int type, int proto)
   mov ebx, AF_INET
   mov ecx, SOCK_STREAM
   mov edx, SOCK_PROTOCOL
   mov eax, SYS_socket
   int 0x80
   test eax, eax
   js _error
   mov [sockfd], eax ; save the fd into memory
.bind:
   ; define the struct by pushing 16 bytes onto the stack
   ; family, port, ip_addr, sin_zero
   push dword SIN_ZERO    ; 4 bytes
   push dword IP_ADDRESS  ; 4 bytes
   push word PORT         ; 2 bytes
   push word AF_INET      ; 2 bytes

   ; bind socket to an IP address and Port
   ; bind(int fd, struct *str, int strlen)
   mov ebx, [sockfd] 
   mov edx, 16
   mov ecx, esp       ; esp is the stack pointer, top AF_INET
   mov eax, SYS_bind
   int 0x80

   add esp, 12        ; pop 12 bytes from the stack
   test eax, eax
   js _error
.listen:
   ; make socket to listen on the bound address
   ; listen(int fd, int backlog)
   mov ebx, [sockfd]
   mov ecx, BACKLOG
   mov eax, SYS_listen
   int 0x80
   test eax, eax
   js _error

   ; print "Listening on the port 3000" in STDOUT
   mov esi, listenMsg
   mov edi, listenMsgLen
   call _print
.accept:
   ; block until a new connection is established
   ; accept4(int fd, struct*, int, int)
   mov ebx, [sockfd]
   mov ecx, 0x0          
   mov edx, 0x0
   mov esi, 0x0
   mov eax, SYS_accept4
   int 0x80

   mov edi, eax   ; save the client socket (eax) in the register (edi)
   call _enqueue  ; enqueue the register
   jmp .accept    ; repeat in loop


; ============================
; ======== _thandle ==========
; ============================
_thandle:
   mov eax, [rear]    ; check queue size
   cmp eax, 0         ; compare
   je .wait           ; wait while queue is empty
   call _dequeue      ; dequeue a connection (element is stored in edi)
   jmp .handle_task   ; handle the task
.wait:
   call _wait_condvar ; wait on futex controlled by an integer (condvar)
   jmp _thandle       ; repeat in loop
.handle_task:
   push edi           ; push edi (connection) onto the stack
   call _handle       ; call the handle function
   pop ebp            ; pop connection from the stack
   jmp _thandle       ; repeat in loop

response: db `HTTP/1.1 200 OK\r\nContent-Length: 22\r\n\r\n<h1>Hello, World!</h1>`, 0
responseLen: equ $- response
; ===========================
; ======== _handle ==========
; ===========================
_handle:
   push ebp               ; create a stack frame
   mov ebp, esp           ; preserve base pointer
   mov ebx, [ebp + 8]     ; 1st argument in the stack (connection)
   pop ebp                ; drop stack frame

   ; write response into the connection socket
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

; ============================
; ======== _pthread ==========
; ============================
; Creates a POSIX thread using a local stack
_pthread:
   ; ebx contains the function pointer (_thandle)
   ; push the function pointer onto the stack
   push ebx

   ; memory allocation (stack-like)
   ; after syscall, 4MB will be allocated in the memory
   ; mmap2(addr*, int len, int prot, int flags)
   mov ebx, 0x0
   mov ecx, STACK_SIZE
   mov edx, PROT_WRITE | PROT_READ
   mov esi, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
   mov eax, SYS_mmap2
   int 0x80

   ; thread creation
   ; clone(int flags, thread_stack*)
   mov ebx, THREAD_FLAGS
   lea ecx, [eax + STACK_SIZE - 8]     ; stack pointer for the thread
   pop dword [ecx]                     ; pop function pointer into ecx (stack pointer)
   mov eax, SYS_clone
   int 0x80
   ret

; ============================
; ======== _enqueue ==========
; ============================
; Enqueue connections into the queue
_enqueue:
   ; edi register contains the connection to be enqueued

   call _lock_mutex                  ; spinlock in mutex
   mov ebx, [rear]                   ; preserve rear pointer
   mov dword [queue + ebx * 4], edi  ; enqueue the connection
   inc dword [rear]                  ; increment the rear pointer (size)
   call _emit_signal                 ; futex wake the any suspended thread
   call _unlock_mutex                ; unlock mutex
   ret

; ============================
; ======== _dequeue ==========
; ============================
; Dequeue connections from the queue
_dequeue:
   call _lock_mutex                 ; spinlock in mutex
   xor ebx, ebx                     ; clear register
   xor edi, edi                     ; clear register
   xor edx, edx                     ; clear register
   lea ecx, [queue]                 ; load queue address into ecx
   mov ebx, [front]                 ; current pointer
   cmp ebx, [rear]                  ; check if reached end of queue
   je .empty                        ; return if empty
   mov edi, dword [ecx + ebx * 4]   ; fetch the 1st element
.shift:
   inc ebx                               ; increment current pointer (next pointer)
   mov edx, dword [ecx + ebx * 4]        ; save next pointer into register
   cmp edx, 0                            ; check if reached end
   je .return                            ; return if reached end
   mov dword [ecx + (ebx - 1) * 4], edx  ; shift the next element into the previous position
   cmp ebx, [rear]                       ; check if reached end of queue
   jle .shift                            ; repeat and keep shifting until end
.return:
   mov dword [ecx + (ebx - 1) * 4], 0    ; empty the last index after shifting
   dec dword [rear]                      ; decrement rear pointer (reduced size)
   call _unlock_mutex                    ; unlock mutex
   ret
.empty:
   mov edi, 0                            ; save into register the value 0 (none)
   call _unlock_mutex                    ; unlock mutex
   ret

; ===============================
; ======== _lock_mutex ==========
; ===============================
_lock_mutex:
   mov eax, 0
   xchg eax, [mutex]   ; atomically exchange mutex value with 0
   test eax, eax       ; test if mutex was previously unlocked
   jnz .done           ; if mutex was previously unlocked, we have successfully locked it
   pause               ; otherwise, spin and retry (reduce CPU usage)
   jmp _lock_mutex     ; keep trying to lock
.done:
   ret

; =================================
; ======== _unlock_mutex ==========
; =================================
_unlock_mutex:
   mov dword [mutex], 1  ; restore original value into mutex
   ret

; =================================
; ======== _wait_condvar ==========
; =================================
; Waits on a condition variable. 
; Uses futex syscall for underlying synchronization and thread scheduling.
_wait_condvar:
   mov ebx, condvar           ; 1st arg: the address of variable
   mov ecx, FUTEX_WAIT | FUTEX_PRIVATE_FLAG ; 2nd arg: futex op
   mov edx, 0		      ; 3rd arg: the target value
   xor esi, esi               ; 4th arg: empty
   xor edi, edi               ; 5th arg: empty
   mov eax, SYS_futex
   int 0x80
   test eax, eax
   jz .done
   jmp _error
.done:
   ret

; ================================
; ======== _emit_signal ==========
; ================================
; Awake threads that are waiting on condition variable.
; Uses futex syscall for underlying synchronization and thread scheduling.
_emit_signal:
   ; 1st: uaddr* | 2nd: futex_op | 3rd: target_val | 4th: empty | 5th: empty
   mov ebx, condvar
   mov ecx, FUTEX_WAKE | FUTEX_PRIVATE_FLAG  ; the difference is in the FUTEX_WAKE flag
   mov edx, 0
   xor esi, esi
   xor edi, edi
   mov eax, SYS_futex
   int 0x80
   ret
