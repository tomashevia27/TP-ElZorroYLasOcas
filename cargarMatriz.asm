global cargarMatriz

section .data
    tableroRotadoIzq    db '-','-','O','O','O','-','-'
                        db '-','-','O',' ',' ','-','-'
                        db 'O','O','O',' ',' ',' ',' '
                        db 'O','O','O',' ','X',' ',' '
                        db 'O','O','O',' ',' ',' ',' '
                        db '-','-','O',' ',' ','-','-'
                        db '-','-','O','O','O','-','-'

    tableroRotadoDer    db '-','-','O','O','O','-','-'
                        db '-','-',' ',' ','O','-','-'
                        db ' ',' ',' ',' ','O','O','O'
                        db ' ',' ','X',' ','O','O','O'
                        db ' ',' ',' ',' ','O','O','O'
                        db '-','-',' ',' ','O','-','-'
                        db '-','-','O','O','O','-','-'

    tableroDadoVuelta   db '-','-',' ',' ',' ','-','-'
                        db '-','-',' ',' ',' ','-','-'
                        db 'O',' ',' ','X',' ',' ','O'
                        db 'O',' ',' ',' ',' ',' ','O'
                        db 'O','O','O','O','O','O','O'
                        db '-','-','O','O','O','-','-'
                        db '-','-','O','O','O','-','-'

    movimientosOca1     db 'SDW'
    movimientosOca2     db 'WAS'
    movimientosOca3     db 'DWA'

    ASCII_I                             equ 73
    ASCII_D                             equ 68
    ASCII_V                             equ 86
    DESPLAZ_ZORRO_TABLERO_ROTADO_IZQ    equ 25
    DESPLAZ_ZORRO_TABLERO_ROTADO_DER    equ 23
    DESPLAZ_ZORRO_TABLERO_DADO_VUELTA   equ 17
    CANTIDAD_CELDAS                     equ 49
    CANTIDAD_MOVIMIENTOS_OCAS           equ 3

section .bss
    dirNuevoTablero     resq 1
    dirNuevosMovOcas    resq 1

section .text
;rdi: dirección efectiva del tablero
;sil:  0 , no se modifica la orientación del tablero, pues ya está cargada la orientación por default
;     'I', sobreescribe la orientación por default, cargando el tablero rotado 90° a Izq
;     'D', sobreescribe la orientación por default, cargando el tablero rotado 90° a Der
;     'V', sobreescribe la orientación por default, cargando el tablero dado vuelta (rotado 180°)
;rdx: dirección del campo de 3 bytes con los movimientos posibles para la oca.
;   - primer byte: movimiento para un costado
;   - segundo byte: movimiento hacia adelante
;   - tercer byte: movimiento hacia el otro costado
;rcx: dirección del desplazamiento del zorro (campo de 64 bits)
cargarMatriz:

    cmp     sil,0
    je      finCarga

    cmp     sil,ASCII_I ; ; 73[10] = Ascii('I')
    jne     verSiEsRotacionDerecha
    mov     qword[dirNuevoTablero],tableroRotadoIzq
    mov     qword[rcx],DESPLAZ_ZORRO_TABLERO_ROTADO_IZQ
    mov     qword[dirNuevosMovOcas],movimientosOca1
    jmp     efectuarCarga

verSiEsRotacionDerecha:
    cmp     sil,ASCII_D ; 68[10] = Ascii('D')
    jne     verSiEsRotacionCompleta
    mov     qword[dirNuevoTablero],tableroRotadoDer
    mov     qword[rcx],DESPLAZ_ZORRO_TABLERO_ROTADO_DER
    mov     qword[dirNuevosMovOcas],movimientosOca2
    jmp     efectuarCarga

verSiEsRotacionCompleta:
    cmp     sil,ASCII_V ; 86[10] = Ascii('V')
    jne     finCarga
    mov     qword[dirNuevoTablero],tableroDadoVuelta
    mov     qword[rcx],DESPLAZ_ZORRO_TABLERO_DADO_VUELTA
    mov     qword[dirNuevosMovOcas],movimientosOca3

efectuarCarga:
    mov     rsi,[dirNuevoTablero]
    mov     rcx,CANTIDAD_CELDAS
    rep movsb

copiarMovimientosOca:
    mov     rsi,[dirNuevosMovOcas]
    mov     rdi,rdx
    mov     rcx,CANTIDAD_MOVIMIENTOS_OCAS
    rep movsb

finCarga:
    ret