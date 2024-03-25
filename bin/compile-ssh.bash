#!/bin/bash

PROGRAM=$1
USER=home/leandronsp
DIR=x86_stuff
TARGET=$USER/$DIR

scp src/x86/$PROGRAM.asm ubuntu:/$TARGET/
ssh ubuntu "nasm -f elf -g -o /$TARGET/$PROGRAM.o /$TARGET/$PROGRAM.asm && ld -m elf_i386 -o /$TARGET/$PROGRAM /$TARGET/$PROGRAM.o"
