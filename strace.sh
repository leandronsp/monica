#!/bin/bash

./build.sh $1
strace ./target/$1 $2
