#!/bin/bash

PROGRAM=$1

nasm -f elf64 -o target/$PROGRAM.o src/$PROGRAM.asm
ld -o target/$PROGRAM target/$PROGRAM.o
objdump -d target/$PROGRAM.o
