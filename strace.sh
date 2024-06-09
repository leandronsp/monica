#!/bin/bash

./build.sh $1
strace -f ./target/$1 $2
