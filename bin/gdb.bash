#!/bin/bash

PROGRAM=$1

nasm -f elf -g -o target/$PROGRAM.o src/x86/$PROGRAM.asm
ld -m elf_i386 -o target/$PROGRAM target/$PROGRAM.o
gdb target/$PROGRAM
