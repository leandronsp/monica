#!/bin/bash

PROGRAM=$1
ARCH=$2
FILENAME=$PROGRAM_$ARCH
NASM_ARCH=elf

if [ "$ARCH" == "x86_64" ]; then
	NASM_ARCH=elf64
fi

nasm -f $NASM_ARCH -o target/$FILENAME.o src/$ARCH/$PROGRAM.asm
ld -o target/$FILENAME target/$FILENAME.o
objdump -d target/$FILENAME.o
./target/$FILENAME
