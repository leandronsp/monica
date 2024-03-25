#!/bin/bash

PROGRAM=$1
USER=home/leandronsp
DIR=x64_stuff
TARGET=$USER/$DIR

scp src/x64/$PROGRAM.asm ubuntu:/$TARGET/
ssh ubuntu "nasm -f elf64 -g -o /$TARGET/$PROGRAM.o /$TARGET/$PROGRAM.asm && ld -o /$TARGET/$PROGRAM /$TARGET/$PROGRAM.o"
