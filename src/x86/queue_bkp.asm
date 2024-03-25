global _start

%define SIZE 10
%define SYS_exit 1

section .data
queue: dd SIZE dup(0) ; initialize array with zero's
front: dd 0 
rear: dd 0 

section .bss
output: resb 1

section .text
_start:
   call initialize

   mov edi, 1
   call _enqueue
   mov edi, 2
   call _enqueue
   mov edi, 3
   call _enqueue

   call _dequeue
   cmp edi, 1
   jne _error

   call _dequeue
   cmp edi, 2
   jne _error

   call _dequeue
   cmp edi, 3
   jne _error

   call _dequeue
   cmp edi, 0
   jne _error

   jmp _exit

initialize:
   mov dword [front], 0
   mov dword [rear], 0
   ret

_enqueue:
    mov ebx, [rear]
    mov dword [queue + ebx * 4], edi ; push into the queue
    inc dword [rear] ; increment the rear pointer
    ret

_dequeue:
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
   ret
.empty:
   mov edi, 0
   ret

_exit:
   xor ebx, ebx
   mov eax, SYS_exit
   int 0x80

_error:
   mov [output], dword `Err\n`
   mov ebx, 1
   mov ecx, output
   mov edx, 4
   mov eax, 4 ; write
   int 0x80

   mov ebx, 1
   mov eax, SYS_exit
   int 0x80
