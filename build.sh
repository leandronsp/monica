#!/bin/bash

nasm -f elf64 -g src/$1.asm -o target/$1.o
ld target/$1.o -o target/$1
