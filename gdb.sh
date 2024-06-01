#!/bin/bash

./build.sh $1
gdb --quiet target/$1
