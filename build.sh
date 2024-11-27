#!/bin/sh
# Replace everything with your favorite programs
# Im using ld.lld cuz it makes nice small programs

#set -xe

fasm src/main.asm main.o
ld.lld main.o -o main -s -e main
rm main.o
