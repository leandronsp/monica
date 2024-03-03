FROM ubuntu
RUN apt-get update && apt-get -y install make binutils gdb build-essential wget
WORKDIR /app
RUN wget https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/nasm-2.16.01.tar.gz -O nasm.tar.gz && tar -xzvf nasm.tar.gz && cd nasm-2.16.01 && ./configure && make && make install