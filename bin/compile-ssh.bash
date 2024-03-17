#!/bin/bash

PROGRAM=$1
USER=home/leandronsp
DIR=x86_stuff

docker compose run app bash -c "nasm -f elf -g -o target/$PROGRAM.o src/x86/$PROGRAM.asm && ld -m elf_i386 -o target/$PROGRAM target/$PROGRAM.o"
scp src/x86/$PROGRAM.asm ubuntu:/$USER/$DIR/
scp target/$PROGRAM* ubuntu:/$USER/$DIR/
