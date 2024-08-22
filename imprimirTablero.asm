global imprimirTablero

%include 'macros.asm'

section .data
    indicesCol          db '   1 2 3 4 5 6 7',0
    filaInc             db '%li     | | | |    ',10,0
    filaComp            db '%li | | | | | | | |',10,0
 
section .bss
    dirTablero          resq 1
    dirFila             resq 1
    esComp              resb 1
    contador            resq 1

section .text
;rdi: dirección de inicio del tablero de 7x7. Al imprimir se omiten las 4 celdas de las 4 esquinas.
;    | | | |    
;    | | | |    
;| | | | | | | |
;| | | | | | | |
;| | | | | | | |
;    | | | |    
;    | | | |    
imprimirTablero:
    mov     [dirTablero],rdi
    mov     qword[contador],1
    mPuts   indicesCol

nuevaFila:
    cmp     qword[contador],8
    je      finImprimir
    cmp     qword[contador],2
    jle     esFilaIncompleta
    cmp     qword[contador],6
    jge     esFilaIncompleta

    mov     byte[esComp],'S'
    mov     qword[dirFila],filaComp

    jmp     llenarAndImprimirFila

esFilaIncompleta:
    mov     byte[esComp],'N'
    mov     qword[dirFila],filaInc

llenarAndImprimirFila:
    sub     rsp,8
    call    llenarFila
    add     rsp,8

    mov     rdi,qword[dirFila]
    mov     rsi,[contador]
    mPrintf

    add     qword[dirTablero],7
    inc     qword[contador]
    jmp     nuevaFila

finImprimir:
    ret
; ******************************
; RUTINAS INTERNAS
; ******************************
llenarFila:
    cmp     byte[esComp],'S'
    je      configurarParaFilaCompleta

    mov     rcx,3
    mov     rsi,[dirTablero]
    add     rsi,2
    lea     rdi,[filaInc + 9]

    jmp     llenarCelda

configurarParaFilaCompleta:
    mov     rcx,7
    mov     rsi,[dirTablero]
    lea     rdi,[filaComp + 5]

llenarCelda:

    mov     al,[rsi]
    mov     [rdi],al

    inc     rsi
    add     rdi,2

    loop    llenarCelda

    ret
; ******************************