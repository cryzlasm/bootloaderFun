#!/bin/bash

nasm -fbin bootloader.asm -o bootloader.bin
if [ $? -ne 0 ]; then
    exit
fi

nasm -fbin kernel.asm -o kernel.bin
if [ $? -ne 0 ]; then
    exit
fi


cat bootloader.bin kernel.bin > result.bin
if [ $? -ne 0 ]; then
    exit
fi


qemu-system-i386 result.bin
