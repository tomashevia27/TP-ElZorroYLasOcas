global calcularDesplazamiento

section .data

section .bss

section .text
;rdi: fila del elemento en la matriz.
;rsi: columna del elemento en la matriz.
;rdx: longitud de una fila de la matriz en bytes (logitudFila = longitudElem * cantColumnas).
;rcx: longitud de un elemento de la matriz en bytes.
;Se asume que los desplazamientos siempre caen dentro de la matriz, por eso no se necesita saber el tamaño de la misma.
;Devuelve el rax el desplazamiento correspondiente.
calcularDesplazamiento:

;   (rdi) = i
;   (rsi) = j

    dec     rdi             ; (rdi) = i - 1 
    imul    rdi,rdx         ; (rdi) = (i - 1) * longFila

    dec     rsi             ; (rsi) = j - 1
    imul    rsi,rcx         ; (rsi) = (j - 1) * longElem

    xor     rax,rax         ; (rax) = 0
    add     rax,rdi         ; (rax) = (rdi) = (i - 1) * longFila
    add     rax,rsi         ; (rax) = (rdi) + (rsi) = (i - 1) * longFila + (j - 1) * longElem

    ret