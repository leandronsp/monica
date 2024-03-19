global _start

%define SIZE 10
%define SYS_write 4
%define SYS_read 3
%define SYS_exit 1
%define STDOUT 1
%define STDIN 0

section .data
queue: dd SIZE dup(0) ; initialize array with zero's
front: dd 0 
rear: dd 0 

section .bss
input: resb 4
newline: resb 4
output: resb 4

section .text
_start:
   call initialize
   call _menu

initialize:
   mov dword [front], 0
   mov dword [rear], 0
   ret

msg1: db `Queue size: `
msg1Len: equ $- msg1
msg2: db "Enqueue a number (or 'd' for dequeue): "
msg2Len: equ $- msg2
doneMsg: db `\n\n===============\n\n`
doneMsgLen: equ $- doneMsg
_menu:
   xor ecx, ecx
   xor edx, edx
   mov byte [input], 0
   mov byte [output], 0

   ; print("Menu: ")
   mov ecx, msg1
   mov edx, msg1Len
   call _print

   ; print(rear)
   mov esi, [rear]
   add esi, '0'
   mov [output], esi
   mov byte [output + 1], 0xA
   mov ecx, output
   call _print

   ; print("Enqueue a number...")
   mov ecx, msg2
   mov edx, msg2Len
   call _print

   ; read -> input
   call _read

   ; enqueue
   mov edi, dword [input] 
   cmp edi, 'd'
   je .dequeue
   call _enqueue
   jmp _menu
.dequeue:
   call _dequeue
   jmp _menu

_enqueue:
    mov ebx, [rear]
    mov dword [queue + ebx * 4], edi ; push into the queue
    inc dword [rear] ; increment the rear pointer
    ret

msg3: db "Element: "
msg3Len: equ $- msg3
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

   ; print("Element: ")
   mov ecx, msg3
   mov edx, msg3Len
   call _print

   ; print(edi)
   mov [output], edi
   mov byte [output + 1], 0xA
   mov ecx, output
   call _print

   ret
.empty:
   mov edi, 0
   ret

_print:
   ; ecx and edx are being set outside
   mov ebx, STDOUT
   mov eax, SYS_write
   int 0x80
   ret

_read:
   mov ebx, STDIN
   mov ecx, input
   mov edx, 1
   mov eax, SYS_read
   int 0x80

   ; consume the remaining bytes
   mov ebx, STDIN
   mov ecx, newline
   mov edx, 1
   mov eax, SYS_read
   int 0x80
   ret

errorMsg: db "An error occurred", 0xA
errorMsgLen: equ $- errorMsg
_error:
   mov ecx, errorMsg
   mov edx, errorMsgLen
   call _print
   jmp _exit

_exit:
   xor ebx, ebx
   mov eax, SYS_exit
   int 0x80
