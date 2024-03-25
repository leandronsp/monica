global _start

%define SYS_exit 1

; []
; rear => 0

; [42]
; 0x804a004
; rear => 1

; [42, 33]
; 0x804a008 => 33
; rear => 2

; [42, 33, 420]
; 0x804a00c => 33
; rear => 3

; dequeue
; [33, 420]
; 0x804a004 => 33
; 0x804a008 => 420
; 0x804a00c => 0
; rear => 2

section .data 
queue: dd 10 dup(0)
rear: dd 0
front: dd 0

section .text
_start:          
   lea esi, [queue]

   mov edi, 3  ; enqueue the number "3"
   call _enqueue ; [3, 0, 0, 0...0]

   mov edi, 8  ; enqueue the number "8"
   call _enqueue ; [3, 8, 0, 0...0]

   call _dequeue ; pop/remove 3 [8, 0, 0, 0...0]
   call _dequeue ; pop/remove 8 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]
   call _dequeue ; pop/remove 0 [0, 0, 0, 0...0]

   mov ebx, 0
   mov eax, SYS_exit
   int 0x80      ; exit(0)

_enqueue:
   mov ecx, [rear]
   mov dword [queue + ecx * 4], edi
   inc dword [rear]
   ret

_dequeue:
   mov edi, [queue]   ; element/value in the memory
   mov ecx, queue     ; memory address

   mov ebx, [front]   ; front pointer
.shift:
   inc ebx
   lea eax, [ecx + ebx * 4] ; next memory address
   mov edx, [eax]
   mov dword [queue + (ebx - 1) * 4], edx
   cmp ebx, [rear]
   jle .shift
   ret
