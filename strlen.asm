global strlen

section .text
; rdi: dir inicio del string
strlen:
    mov     rax,0
siguienteCaracter:
    cmp     byte[rdi + rax],0
    je      finDeString
    inc     rax
    jmp     siguienteCaracter
finDeString:
    ret