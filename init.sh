#!/bin/bash

if [ $1 == "clean" ]; then
    rm -f *.o juegoZorroYOcas *.lst
    exit 1
fi

if [ $# -eq 0 ]; then
    nasm zorro.asm -f elf64
    nasm calcularDesplazamiento.asm -f elf64
    nasm imprimirTablero.asm -f elf64
    nasm cargarMatriz.asm -f elf64
    nasm strlen.asm -f elf64
    nasm reemplazarIconos.asm -f elf64
elif [ $1 == "debug" ]; then
    nasm zorro.asm -f elf64 -g -F dwarf -l zorro.lst
    nasm calcularDesplazamiento.asm -f elf64 -g -F dwarf -l calcularDesplazamiento.lst
    nasm imprimirTablero.asm -f elf64 -g -F dwarf -l imprimirTablero.lst
    nasm cargarMatriz.asm -f elf64 -g -F dwarf -l cargarMatriz.lst
    nasm strlen.asm -f elf64 -g -F dwarf -l strlen.lst
    nasm reemplazarIconos.asm -f elf64 -g -F dwarf -l reemplazarIconos.lst
else
    exit 1
fi

gcc *.o -o juegoZorroYOcas -no-pie

if [ $# -eq 0 ]; then
    ./juegoZorroYOcas
else
    gdb juegoZorroYOcas
fi