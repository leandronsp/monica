global _start

%define SYS_futex 202      ; futex
%define SYS_mmap 9        ; allocate memory into heap
%define SYS_clone 56       ; create thread
%define SYS_socket 41      ; open socket
%define SYS_bind 49        ; bind to open socket
%define SYS_listen 50      ; listen to the socket
%define SYS_accept4 288    ; accept connections to the socket
%define SYS_write 1        ; write
%define SYS_read 0         ; read
%define SYS_open 2         ; open
%define SYS_close 3        ; close
%define SYS_exit 60        ; exit
%define SYS_exit_group 231 ; exit

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
queue: dq QUEUE_SIZE dup(0) ; initialize array with zero's
queuePtr: dq 0		    ; the front pointer for connection queue
mutex: dq 1                 ; a shared variable to synchronize threads in spinlock
condvar: dq 0               ; a shared variable to synchronize threads in futex

section .text
_start:	            
   mov r8, 0           ; thread pool counter
.pool:
   mov rdi, _thandle    ; save the function pointer to be used in the thread
   call _pthread        ; create a new thread
   inc r8
   cmp r8, 1           ; pool size
   je .program
   jmp .pool
.program:
   mov r8, 42
   call _enqueue  ; enqueue the register


; ============================
; ======== _thandle ==========
; ============================
_thandle:
   mov rax, [queuePtr]    ; check queue size
   cmp rax, 0         ; compare
   je .wait           ; wait while queue is empty
   call _dequeue      ; dequeue a connection (element is stored in r8)
   jmp _thandle
.wait:
   call _wait_condvar ; wait on futex controlled by an integer (condvar)
   jmp _thandle       ; repeat in loop

_pthread:
   ; rdi contains the function pointer (_thandle)
   ; push the function pointer onto the stack
   push rdi

   ; memory allocation (stack-like)
   ; after syscall, 4MB will be allocated in the memory
   ; mmap(addr*, int len, int prot, int flags)
   mov rdi, 0x0
   mov rsi, STACK_SIZE
   mov rdx, PROT_WRITE | PROT_READ
   mov r10, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
   mov rax, SYS_mmap
   syscall

   ; thread creation
   ; clone(int flags, thread_stack*)
   mov rdi, THREAD_FLAGS
   lea rsi, [rax + STACK_SIZE - 8]     ; stack pointer for the thread
   pop qword [rsi]
   mov rax, SYS_clone
   syscall
   ret

; ============================
; ======== _enqueue ==========
; ============================
; Enqueue connections into the queue
_enqueue:
   ; r8 register contains the connection to be enqueued

   call _lock_mutex                  ; spinlock in mutex
   mov rdi, [queuePtr]                   ; preserve rear pointer
   mov [queue + rdi], r8  ; enqueue the connection
   inc qword [queuePtr]                  ; increment the rear pointer (size)
   call _emit_signal                 ; futex wake the any suspended thread
   call _unlock_mutex                ; unlock mutex
   ret

; ============================
; ======== _dequeue ==========
; ============================
; Dequeue connections from the queue
_dequeue:
	xor r8, r8
	xor rsi, rsi

	mov r8b, [queue]
	mov rcx, 0
.loop_dequeue:
	cmp byte [queuePtr], 0
	je .return_dequeue

	cmp cl, [queuePtr]
	je .done_dequeue

	; shift
	xor r10, r10
	mov r10b, [queue + rcx + 1]
	mov byte [queue + rcx], r10b

	inc rcx
	jmp .loop_dequeue
.done_dequeue:
	dec byte [queuePtr]
.return_dequeue:
	ret

; ===============================
; ======== _lock_mutex ==========
; ===============================
_lock_mutex:
   mov rax, 0
   xchg rax, [mutex]   ; atomically exchange mutex value with 0
   test rax, rax       ; test if mutex was previously unlocked
   jnz .done           ; if mutex was previously unlocked, we have successfully locked it
   pause               ; otherwise, spin and retry (reduce CPU usage)
   jmp _lock_mutex     ; keep trying to lock
.done:
   ret

; =================================
; ======== _unlock_mutex ==========
; =================================
_unlock_mutex:
   mov qword [mutex], 1  ; restore original value into mutex
   ret

; =================================
; ======== _wait_condvar ==========
; =================================
; Waits on a condition variable. 
; Uses futex syscall for underlying synchronization and thread scheduling.
_wait_condvar:
   mov rdi, condvar           ; 1st arg: the address of variable
   mov rsi, FUTEX_WAIT | FUTEX_PRIVATE_FLAG ; 2nd arg: futex op
   mov rdx, 0		      ; 3rd arg: the target value
   xor r10, r10               ; 4th arg: empty
   xor r8, r8               ; 5th arg: empty
   mov rax, SYS_futex
   syscall
   test rax, rax
   jz .done
.done:
   ret

; ================================
; ======== _emit_signal ==========
; ================================
; Awake threads that are waiting on condition variable.
; Uses futex syscall for underlying synchronization and thread scheduling.
_emit_signal:
   ; 1st: uaddr* | 2nd: futex_op | 3rd: target_val | 4th: empty | 5th: empty
   mov rdi, condvar
   mov rsi, FUTEX_WAKE | FUTEX_PRIVATE_FLAG  ; the difference is in the FUTEX_WAKE flag
   mov rdx, 0
   xor r10, r10
   xor r8, r8
   mov rax, SYS_futex
   syscall
   ret
