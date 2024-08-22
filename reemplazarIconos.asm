global reemplazarIconos

section .text
    ICONO_ZORRO_DEFAULT     equ 'X'
    ICONO_OCAS_DEFAULT      equ 'O'
    CANTIDAD_CELDAS         equ 49

section .bss

section .text
;rdi: dirección del tablero
;sil: nuevo ícono para el zorro
;dl: nuevo ícono para las ocas
reemplazarIconos:
    mov     rcx,CANTIDAD_CELDAS

reemplazarIcono:
    cmp     byte[rdi],ICONO_ZORRO_DEFAULT
    jne     verSiHayOca
    mov     byte[rdi],sil
    jmp     avanzarSig

verSiHayOca:
    cmp     byte[rdi],ICONO_OCAS_DEFAULT
    jne     avanzarSig
    mov     byte[rdi],dl

avanzarSig:
    inc     rdi
    loop    reemplazarIcono

    ret