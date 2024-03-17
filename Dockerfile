FROM --platform=linux/amd64 ubuntu
RUN apt-get update
RUN apt-get install make binutils build-essential -y
RUN apt-get install nasm gdb strace -y
WORKDIR /app
