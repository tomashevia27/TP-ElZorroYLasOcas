global main

extern cargarMatriz
extern reemplazarIconos
extern imprimirTablero
extern calcularDesplazamiento
extern strlen

%include 'macros.asm'

; %1 -> ΔD (cambio en el desplazamiento)
; %2 -> columna a chequear (-1 si no se debe chequear)
; %3 -> fila a chequear (-1 si no se debe chequear)
; %4 -> SIG columna a chequear (-1 si no se debe chequear)
; %5 -> SIG fila a chequear (-1 si no se debe chequear)
; %6 -> dirección campo de memoria (64 bits) del contador de movimiento a incrementar
%macro mCargarParametrosMovimientoZorro 6
    mov     r8,%1
    mov     r9,%2
    mov     r10,%3
    mov     r11,%4
    mov     r12,%5
    mov     r13,%6
%endmacro

%macro mMostrarEstadisticas 2
    mov     rdi,msgEstadisticas
    mov     rsi,%1
    mov     rdx,%2
    mPrintf
%endmacro

%macro mImprimirPrompt 0
    mov     rdi,prompt
    mPrintf
%endmacro

%macro mInterrumpirPartida 1
    cmp     %1,'q'
    je      interrupcionDePartida
%endmacro

%macro mGuardarPartida 1
    cmp     %1,'g'
    je      guardarPartida
%endmacro

section .data
    dataPartida     times 0 db ' '
    tablero                 db '-','-','O','O','O','-','-'
                            db '-','-','O','O','O','-','-'
                            db 'O','O','O','O','O','O','O'
                            db 'O',' ',' ',' ',' ',' ','O'
                            db 'O',' ',' ','X',' ',' ','O'
                            db '-','-',' ',' ',' ','-','-'
                            db '-','-',' ',' ',' ','-','-'
    desplazamientoZorro     dq 31
    movimientosOca  times 0 db ' '
    movOcaCostado1          db 'A'
    movOcaAdelante          db 'S'
    movOcaCostado2          db 'D'
    turnoZorro              db 1
    ocasComidas             db 0
    cantMovZorroIzq         dq 0
    cantMovZorroDer         dq 0
    cantMovZorroArr         dq 0
    cantMovZorroAbj         dq 0
    cantMovZorroArrIzq      dq 0
    cantMovZorroArrDer      dq 0
    cantMovZorroAbjIzq      dq 0
    cantMovZorroAbjDer      dq 0
    iconoZorro              db 'X'
    iconoOca                db 'O'

;   Constantes
    LONGITUD_ELEM           equ 1
    LONGITUD_FILA           equ 7
    DESPLAZ_IZQ             equ -LONGITUD_ELEM
    DESPLAZ_DER             equ LONGITUD_ELEM
    DESPLAZ_ARR             equ -LONGITUD_FILA
    DESPLAZ_ABJ             equ LONGITUD_FILA
    DESPLAZ_ARR_IZQ         equ -LONGITUD_FILA - LONGITUD_ELEM
    DESPLAZ_ARR_DER         equ -LONGITUD_FILA + LONGITUD_ELEM
    DESPLAZ_ABJ_IZQ         equ LONGITUD_FILA - LONGITUD_ELEM
    DESPLAZ_ABJ_DER         equ LONGITUD_FILA + LONGITUD_ELEM
    COL_MIN                 equ 1
    FIL_MIN                 equ 1
    COL_MAX                 equ 7
    FIL_MAX                 equ 7
    SIG_COL_MIN             equ 2
    SIG_FIL_MIN             equ 2
    SIG_COL_MAX             equ 6
    SIG_FIL_MAX             equ 6
    NO_CHEQUEAR             equ -1
    OBJETIVO_OCAS           equ 12
    ES_TURNO_ZORRO          equ 1
    ES_TURNO_OCAS           equ 0

    prompt                      db '>>> ',0
    msgBienvenida               db '¡Bienvenido a El Zorro y las Ocas!',0
    msgComandosDisponibles      db 'Ingrese g en cualquier momento para guardar la partida actual',10
                                db 'Ingrese q en cualquier momento para salir del juego',0
    msgCargarPartidaExistente   db '¿Quieres cargar una partida? [s/n]',0
    modoAperturaArchLectura     db 'rb',0
    modoAperturaArchEscritura   db 'wb',0
    msgPedirNombreArch          db 'Ingresar el nombre del archivo',0
    msgPedirNombreNuevaPartida  db '¿Qué nombre quiere ponerle a la partida? (debe ser un archivo .dat)',0
    msgNombreArchInvalido       db '¡La extensión es incorrecta o el nombre es muy corto!',10
                                db 'Pruebe con <nombre_partida>.dat',0
    msgPartidaGuardada          db '¡Partida guardada!',0
    msgYaExiste                 db 'Ya existe una partida con ese nombre. Intente con otro',0
    msgErrorAperturaArch        db 'La partida buscada no existe, vuelva a intentarlo o inicie una nueva partida',0
    msgErrorLecturaArch         db 'Error al leer el archivo',0
    msgTurnoZorro               db '¡Turno del zorro!',0
    msgMovimientoZorro          db 'Ingrese un movimiento para el zorro',0
    msgElegirOrientacion        db 'Elija una orientación para el tablero (sin rotar por default sin ingresar nada)',10
                                db '    - I para rotar a Izquierda',10
                                db '    - D para rotar a Derecha',10
                                db '    - V para dar vuelta',0
    msgElegirIconoZorro         db 'Elija un ícono para el zorro (X por default sin ingresar nada)',0
    msgElegiriconoOca           db 'Elija un ícono para la oca (O por default sin ingresar nada)',0
    comandoClear                db 'clear',0
    msgTurnoOcas                db '¡Turno de las ocas!',0
    msgPedirPosicionOca         db 'Ingrese fila (1 a 7) y columna (1 a 7) separados por un espacio',0
    formatoPosicionOca          db '%hhi %hhi',0
    msgPedirMovimientoOca       db 'Ingrese un movimiento para la oca',0
    msgNoHayOca                 db '¡Allí no hay una oca! Elija otra posición',0
    msgOcaNoPuedeMoverse        db '¡La oca elegida no puede moverse hacia ningún lado! Elija otra oca',0
    msgHaGanadoElZorro          db '¡Ha ganado el Zorro! Se han comido efectivamente las 12 ocas',0
    msgHanGanadoLasOcas         db '¡Han ganado las ocas! El zorro está completamente acorralado',0
    msgEstadisticas             db 'Cantidad de movimientos en la dirección <%s> = %li',10,0
    msgIzq                      db 'Izquierda',0
    msgDer                      db 'Derecha',0
    msgArr                      db 'Arriba',0
    msgAbj                      db 'Abajo',0
    msgArrIzq                   db 'Arriba-Izquierda',0
    msgArrDer                   db 'Arriba-Derecha',0
    msgAbjIzq                   db 'Abajo-Izquierda',0
    msgAbjDer                   db 'Abajo-Derecha',0
    msgInterrupcionPartida      db '¡Se ha interrumpido la partida!',0

section .bss
    eleccionPartida             resb 10
    nombreArch                  resb 50
    nombreArchNuevaPartida      resb 50
    orientacionTablero          resb 10
    inputIconoZorro             resb 10
    inputIconoOca               resb 10
    movimientoZorro             resb 10
    movimientoOca               resb 10
    posicionOca                 resb 10
    
    filOca                      resb 1
    colOca                      resb 1

    fileHandler                 resq 1
    fileHandlerNuevaPartida     resq 1
    
    RESULTELECCION              resb 1
    RESULTMOVZORRO              resb 1
    RESULTMOVOCA                resb 1
    RESULTORIENTACION           resb 1
    RESULTNOMBREARCH            resb 1
    
section .text
main:
mostrarMensajeIntroduccion:
    mPuts   msgBienvenida
    mPuts   msgComandosDisponibles

preguntarCargarPartidaExistente:
    mPuts   msgCargarPartidaExistente
    mImprimirPrompt
    mGets   eleccionPartida

    mInterrumpirPartida byte[eleccionPartida]

    sub     rsp,8
    call    validarEleccion
    add     rsp,8

    cmp     byte[RESULTELECCION],'S'
    jne     preguntarCargarPartidaExistente

    cmp     byte[eleccionPartida],'s'
    jne     nuevaPartida

cargarPartidaExistente:
pedirNombreArchivo:
    mPuts   msgPedirNombreArch
    mImprimirPrompt
    mGets   nombreArch

    mInterrumpirPartida byte[nombreArch]

    mFopen  nombreArch,modoAperturaArchLectura
    cmp     rax,0
    jle     errorAperturaArchivo
    mov     [fileHandler],rax

    mFread  dataPartida,128,1,qword[fileHandler]
    cmp     rax,1
    jl      errorLecturaArchivo

    mFclose qword[fileHandler]
    jmp     loopPrincipal

errorAperturaArchivo:
    mPuts   msgErrorAperturaArch
    jmp     preguntarCargarPartidaExistente

errorLecturaArchivo:
    mFclose qword[fileHandler]
    mPuts   msgErrorLecturaArch
    jmp     preguntarCargarPartidaExistente

nuevaPartida:
pedirOrientacion:
    mPuts   msgElegirOrientacion
    mImprimirPrompt
    mGets   orientacionTablero

    mInterrumpirPartida byte[orientacionTablero]

    sub     rsp,8
    call    validarOrientacion
    add     rsp,8

    cmp     byte[RESULTORIENTACION],'S'
    jne     pedirOrientacion

pedirIconoZorro:
    mPuts   msgElegirIconoZorro
    mImprimirPrompt
    mGets   inputIconoZorro
    mInterrumpirPartida byte[inputIconoZorro]
    cmp     byte[inputIconoZorro],0
    je      pedirIconoOca
    mov     al,byte[inputIconoZorro]
    mov     [iconoZorro],al

pedirIconoOca:
    mPuts   msgElegiriconoOca
    mImprimirPrompt
    mGets   inputIconoOca
    mInterrumpirPartida byte[inputIconoOca]
    cmp     byte[inputIconoOca],0
    je      setearTablero
    mov     al,byte[inputIconoOca]
    mov     [iconoOca],al

setearTablero:
    mov     rdi,tablero
    xor     rsi,rsi
    mov     sil,[orientacionTablero]
    mov     rdx,movimientosOca
    mov     rcx,desplazamientoZorro
    sub     rsp,8
    call    cargarMatriz
    add     rsp,8

    mov     rdi,tablero
    xor     rsi,rsi
    mov     sil,[iconoZorro]
    xor     rdx,rdx
    mov     dl,[iconoOca]
    sub     rsp,8
    call    reemplazarIconos
    add     rsp,8

loopPrincipal:

    mSystem comandoClear

    mov     rdi,tablero
    sub     rsp,8
    call    imprimirTablero
    add     rsp,8

    cmp     byte[ocasComidas],OBJETIVO_OCAS
    je      ganoZorro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
verZorroEncerrado:
    mov     rbx,[desplazamientoZorro]   ; posicion del zorro
    xor     rdx,rdx                     ; (rdx) = 0
    mov     rax,rbx                     ; (rax) = desplazamiento del zorro en el tablero
    mov     r15,LONGITUD_FILA
    idiv    r15                         ; (rdx:rax) / op -> (rdx) = resto, (rax) = cociente
    inc     rdx                         ; (rdx) = columna zorro = resto + 1
    inc     rax                         ; (rax) = fila zorro = cociente + 1

verSiZorroPuedeMoverseIzquierda:
    cmp     rdx,COL_MIN
    je      verSiZorroPuedeMoverseDerecha
     
    cmp     byte[tablero + rbx + DESPLAZ_IZQ],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_IZQ],al
    je      verificarColumnaIzq
    jmp     verSiZorroPuedeMoverseDerecha

verificarColumnaIzq:
    cmp     rdx,SIG_COL_MIN
    je      verSiZorroPuedeMoverseDerecha
    cmp     byte[tablero + rbx + DESPLAZ_IZQ + DESPLAZ_IZQ],' '
    je      continuarJuego

verSiZorroPuedeMoverseDerecha:
    cmp     rdx,COL_MAX
    je      verSiZorroPuedeMoverseAbajoDerecha
     
    cmp     byte[tablero + rbx + DESPLAZ_DER],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_DER],al
    je      verificarColumnaDer
    jmp     verSiZorroPuedeMoverseAbajoDerecha

verificarColumnaDer:
    cmp     rdx,SIG_COL_MAX
    je      verSiZorroPuedeMoverseAbajoDerecha
    cmp     byte[tablero + rbx + DESPLAZ_DER + DESPLAZ_DER],' '
    je      continuarJuego

verSiZorroPuedeMoverseAbajoDerecha:
    cmp     rdx,COL_MAX
    je      verSiZorroPuedeMoverseAbajo
    cmp     rax,FIL_MAX
    je      verSiZorroPuedeMoverseAbajo
     
    cmp     byte[tablero + rbx + DESPLAZ_ABJ_DER],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_ABJ_DER],al
    je      verificarFilaColumnaDiagonalAbajoDerecha
    jmp     verSiZorroPuedeMoverseAbajo

verificarFilaColumnaDiagonalAbajoDerecha:
    cmp     rdx,SIG_COL_MAX
    je      verSiZorroPuedeMoverseAbajo
    cmp     rax,SIG_FIL_MAX
    je      verSiZorroPuedeMoverseAbajo
    cmp     byte[tablero + rbx + DESPLAZ_ABJ_DER + DESPLAZ_ABJ_DER],' '
    je      continuarJuego

verSiZorroPuedeMoverseAbajo:
    cmp     rax,FIL_MAX  
    je      verSiZorroPuedeMoverseAbajoIzquierda
     
    cmp     byte[tablero + rbx + DESPLAZ_ABJ],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_ABJ],al
    je      verificarFilaAbajo
    jmp     verSiZorroPuedeMoverseAbajoIzquierda

verificarFilaAbajo:
    cmp     rax,SIG_FIL_MAX
    je      verSiZorroPuedeMoverseAbajoIzquierda
    cmp     byte[tablero + rbx + DESPLAZ_ABJ + DESPLAZ_ABJ],' '
    je      continuarJuego

verSiZorroPuedeMoverseAbajoIzquierda:
    cmp     rdx,COL_MIN  
    je      verSiZorroPuedeMoverseArribaIzquierda
    cmp     rax,FIL_MAX  
    je      verSiZorroPuedeMoverseArribaIzquierda
     
    cmp     byte[tablero + rbx + DESPLAZ_ABJ_IZQ],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_ABJ_IZQ],al
    je      verificarFilaColumnaAbajoIzquierda
    jmp     verSiZorroPuedeMoverseArribaIzquierda

verificarFilaColumnaAbajoIzquierda:
    cmp     rdx,SIG_COL_MIN
    je      verSiZorroPuedeMoverseArribaIzquierda
    cmp     rax,SIG_FIL_MAX
    je      verSiZorroPuedeMoverseArribaIzquierda
    cmp     byte[tablero + rbx + DESPLAZ_ABJ_IZQ + DESPLAZ_ABJ_IZQ],' '
    je      continuarJuego
    
verSiZorroPuedeMoverseArribaIzquierda:
    cmp     rdx,COL_MIN  
    je      verSiZorroPuedeMoverseArriba
    cmp     rax,FIL_MIN 
    je      verSiZorroPuedeMoverseArriba
     
    cmp     byte[tablero + rbx + DESPLAZ_ARR_IZQ],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_ARR_IZQ],al
    je      verificarFilaColumnaArribaIzquierda
    jmp     verSiZorroPuedeMoverseArriba

verificarFilaColumnaArribaIzquierda:
    cmp     rdx,SIG_COL_MIN
    je      verSiZorroPuedeMoverseArriba
    cmp     rax,SIG_FIL_MIN
    je      verSiZorroPuedeMoverseArriba
    cmp     byte[tablero + rbx + DESPLAZ_ARR_IZQ + DESPLAZ_ARR_IZQ],' '
    je      continuarJuego

verSiZorroPuedeMoverseArriba:
    cmp     rax,FIL_MIN 
    je      verSiZorroPuedeMoverseArribaDerecha
     
    cmp     byte[tablero + rbx + DESPLAZ_ARR],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_ARR],al
    je      verificarFilaArriba
    jmp     verSiZorroPuedeMoverseArribaDerecha

verificarFilaArriba:
    cmp     rax,SIG_FIL_MIN
    je      verSiZorroPuedeMoverseArribaDerecha
    cmp     byte[tablero + rbx + DESPLAZ_ARR + DESPLAZ_ARR],' '
    je      continuarJuego

verSiZorroPuedeMoverseArribaDerecha:
    cmp     rdx,COL_MAX
    je      ganaronOcas
    cmp     rax,FIL_MIN 
    je      ganaronOcas
     
    cmp     byte[tablero + rbx + DESPLAZ_ARR_DER],' '
    je      continuarJuego
    mov     al,[iconoOca]
    cmp     byte[tablero + rbx + DESPLAZ_ARR_DER],al
    je      verificarFilaColumnaArribaDerecha
    jmp     ganaronOcas

verificarFilaColumnaArribaDerecha:
    cmp     rdx,SIG_COL_MAX
    je      ganaronOcas
    cmp     rax,SIG_FIL_MIN
    je      ganaronOcas
    cmp     byte[tablero + rbx + DESPLAZ_ARR_DER + DESPLAZ_ARR_DER],' '
    jne     ganaronOcas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

continuarJuego:
    cmp     byte[turnoZorro],ES_TURNO_ZORRO
    je      pedirMovimientoZorro

    jmp     moverOcas

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOVER ZORRO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pedirMovimientoZorro:
    mPuts   msgTurnoZorro
    mPuts   msgMovimientoZorro
    mImprimirPrompt
    mGets   movimientoZorro

    mInterrumpirPartida byte[movimientoZorro]
    mGuardarPartida     byte[movimientoZorro]

    sub     rsp,8
    call    validarMovimientoZorro
    add     rsp,8

    cmp     byte[RESULTMOVZORRO],'S'
    jne     pedirMovimientoZorro

    cmp     byte[movimientoZorro],'A'
    jne     verSiEsMovDer
    mCargarParametrosMovimientoZorro DESPLAZ_IZQ,COL_MIN,NO_CHEQUEAR,SIG_COL_MIN,NO_CHEQUEAR,cantMovZorroIzq
    jmp     moverZorro

verSiEsMovDer:
    cmp     byte[movimientoZorro],'D'
    jne     verSiEsMovArr
    mCargarParametrosMovimientoZorro DESPLAZ_DER,COL_MAX,NO_CHEQUEAR,SIG_COL_MAX,NO_CHEQUEAR,cantMovZorroDer
    jmp     moverZorro

verSiEsMovArr:
    cmp     byte[movimientoZorro],'W'
    jne     verSiEsMovAbj
    mCargarParametrosMovimientoZorro DESPLAZ_ARR,NO_CHEQUEAR,FIL_MIN,NO_CHEQUEAR,SIG_FIL_MIN,cantMovZorroArr
    jmp     moverZorro

verSiEsMovAbj:
    cmp     byte[movimientoZorro],'S'
    jne     verSiEsMovArrIzq
    mCargarParametrosMovimientoZorro DESPLAZ_ABJ,NO_CHEQUEAR,FIL_MAX,NO_CHEQUEAR,SIG_FIL_MAX,cantMovZorroAbj
    jmp     moverZorro

verSiEsMovArrIzq:
    cmp     byte[movimientoZorro],'Q'
    jne     verSiEsMovArrDer
    mCargarParametrosMovimientoZorro DESPLAZ_ARR_IZQ,COL_MIN,FIL_MIN,SIG_COL_MIN,SIG_FIL_MIN,cantMovZorroArrIzq
    jmp     moverZorro 

verSiEsMovArrDer:
    cmp     byte[movimientoZorro],'E'
    jne     verSiEsMovAbjIzq
    mCargarParametrosMovimientoZorro DESPLAZ_ARR_DER,COL_MAX,FIL_MIN,SIG_COL_MAX,SIG_FIL_MIN,cantMovZorroArrDer
    jmp     moverZorro

verSiEsMovAbjIzq:
    cmp     byte[movimientoZorro],'Z'
    jne     esMovAbjDer
    mCargarParametrosMovimientoZorro DESPLAZ_ABJ_IZQ,COL_MIN,FIL_MAX,SIG_COL_MIN,SIG_FIL_MAX,cantMovZorroAbjIzq
    jmp     moverZorro

esMovAbjDer:
    mCargarParametrosMovimientoZorro DESPLAZ_ABJ_DER,COL_MAX,FIL_MAX,SIG_COL_MAX,SIG_FIL_MAX,cantMovZorroAbjDer

moverZorro:
    mov     rbx,[desplazamientoZorro]

;   Recuperar posición del zorro
    xor     rdx,rdx                 ; (rdx) = 0
    mov     rax,rbx                 ; (rax) = desplazamiento del zorro en el tablero
    mov     r15,LONGITUD_FILA
    idiv    r15                     ; (rdx:rax) / op -> (rdx) = resto, (rax) = cociente
    inc     rdx                     ; (rdx) = columna zorro = resto + 1
    inc     rax                     ; (rax) = fila zorro = cociente + 1

;   Ver si el zorro está en un borde del tablero peligroso para el movimiento en cuestión
;   Si lo está, se pide otro movimiento
    cmp     rdx,r9
    je      pedirMovimientoZorro
    cmp     rax,r10
    je      pedirMovimientoZorro
        
    add     rbx,r8

;   Omitir caso en el que se quiera comer a una oca que está en el borde del tablero
;   En ese caso, directamente se compara con un vacío
    cmp     rdx,r11
    je      compararVacio
    cmp     rax,r12
    je      compararVacio

;   Ver si en la posición adyacente en la dirección indicada hay una oca
    mov     al,byte[tablero + rbx]
    cmp     al,[iconoOca]
    jne     compararVacio

;   Si la hay, ver si la posición adyacente a la oca en esa misma dirección está vacía
    add     rbx,r8
    cmp     byte[tablero + rbx],' '

;   Si no lo está se pedirá un nuevo movimiento
    jne     pedirMovimientoZorro

;   Si lo está, se modifica el desplazamiento del zorro y se come a la oca, incrementando la cantidad de ocas comidas
    mov     [desplazamientoZorro],rbx

    mov     al,[iconoZorro]
    mov     byte[tablero + rbx],al
    sub     rbx,r8
    mov     byte[tablero + rbx],' '
    sub     rbx,r8
    mov     byte[tablero + rbx],' '
    inc     byte[ocasComidas]
    inc     qword[r13]

;   Como el zorro ha comido una oca, sigue siendo su turno
    jmp     loopPrincipal

compararVacio:
;   Si no había una oca, se verifica si la posición está libre. Si no lo está se pedirá un nuevo movimiento
    cmp     byte[tablero + rbx],' '
    jne     pedirMovimientoZorro

;   Si lo está, se modifica el desplazamiento del zorro y se mueve a la posición adyacente en la dirección indicada
    mov     [desplazamientoZorro],rbx

    mov     al,[iconoZorro]
    mov     byte[tablero + rbx],al
    sub     rbx,r8
    mov     byte[tablero + rbx],' '
    inc     qword[r13]

;   Deja de ser el turno del zorro. Ahora es el turno de las ocas
    mov     byte[turnoZorro],ES_TURNO_OCAS
    jmp     loopPrincipal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOVER OCAS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
moverOcas:
    mPuts   msgTurnoOcas
pedirPosicionOca:
    mPuts   msgPedirPosicionOca
    mImprimirPrompt
    mGets   posicionOca

    mInterrumpirPartida byte[posicionOca]
    mGuardarPartida     byte[posicionOca]

    mov     rdi,posicionOca
    mov     rsi,formatoPosicionOca
    mov     rdx,filOca
    mov     rcx,colOca
    mSscanf

    cmp     rax,2
    jl      pedirPosicionOca

    xor     rdi,rdi
    mov     dil,[filOca]
    xor     rsi,rsi
    mov     sil,[colOca]
    mov     rdx,LONGITUD_FILA
    mov     rcx,LONGITUD_ELEM
    sub     rsp,8
    call    calcularDesplazamiento
    add     rsp,8

    mov     rbx,rax
    mov     al,byte[tablero + rbx]
    cmp     al,[iconoOca]
    je      verSiOcaPuedeMoverse

    mPuts   msgNoHayOca
    jmp     pedirPosicionOca

verSiOcaPuedeMoverse:
verSiOcaPuedeMoverseIzq:
    cmp     byte[movOcaAdelante],'D'
    je      verSiOcaPuedeMoverseDer	
    cmp     byte[tablero + rbx + DESPLAZ_IZQ],' '
    je      pedirMovimientoOca

verSiOcaPuedeMoverseDer:
    cmp     byte[movOcaAdelante],'I'
    je      verSiOcaPuedeMoverseArr
    cmp     byte[tablero + rbx + DESPLAZ_DER],' '
    je      pedirMovimientoOca

verSiOcaPuedeMoverseArr:
    cmp     byte[movOcaAdelante],'S'
    je      verSiOcaPuedeMoverseAbj
    cmp     byte[tablero + rbx + DESPLAZ_ARR],' '
    je      pedirMovimientoOca

verSiOcaPuedeMoverseAbj:
    cmp     byte[movOcaAdelante],'W'
    je      ocaNoPuedeMoverse
    cmp     byte[tablero + rbx + DESPLAZ_ABJ],' '
    je      pedirMovimientoOca

ocaNoPuedeMoverse:
    mPuts   msgOcaNoPuedeMoverse
    jmp     pedirPosicionOca

pedirMovimientoOca:
    mPuts   msgPedirMovimientoOca
    mImprimirPrompt
    mGets   movimientoOca

    mInterrumpirPartida byte[movimientoOca]
    mGuardarPartida     byte[movimientoOca]

    sub     rsp,8
    call    validarMovimientoOca
    add     rsp,8

    cmp     byte[RESULTMOVOCA],'S'
    jne     pedirMovimientoOca

    cmp     byte[movimientoOca],'A'
    jne     moverOcaDer
    cmp     byte[colOca],COL_MIN
    je      pedirMovimientoOca
    cmp     byte[tablero + rbx + DESPLAZ_IZQ],' '
    jne     pedirMovimientoOca
    mov     al,[iconoOca]
    mov     [tablero + rbx + DESPLAZ_IZQ],al
    mov     byte[tablero + rbx],' '
    jmp     esTurnoZorro

moverOcaDer:
    cmp     byte[movimientoOca],'D'
    jne     moverOcaArr
    cmp     byte[colOca],COL_MAX
    je      pedirMovimientoOca
    cmp     byte[tablero + rbx + DESPLAZ_DER],' '
    jne     pedirMovimientoOca
    mov     al,[iconoOca]
    mov     [tablero + rbx + DESPLAZ_DER],al
    mov     byte[tablero + rbx],' '
    jmp     esTurnoZorro

moverOcaArr:
    cmp     byte[movimientoOca],'W'
    jne     moverOcaAbj
    cmp     byte[filOca],FIL_MIN
    je      pedirMovimientoOca
    cmp     byte[tablero + rbx + DESPLAZ_ARR],' '
    jne     pedirMovimientoOca
    mov     al,[iconoOca]
    mov     [tablero + rbx + DESPLAZ_ARR],al
    mov     byte[tablero + rbx],' '
    jmp     esTurnoZorro

moverOcaAbj:
    cmp     byte[filOca],FIL_MAX
    je      pedirMovimientoOca
    cmp     byte[tablero + rbx + DESPLAZ_ABJ],' '
    jne     pedirMovimientoOca
    mov     al,[iconoOca]
    mov     [tablero + rbx + DESPLAZ_ABJ],al
    mov     byte[tablero + rbx],' '

esTurnoZorro:
    mov     byte[turnoZorro],ES_TURNO_ZORRO
    jmp     loopPrincipal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ganoZorro:
    mPuts   msgHaGanadoElZorro
    jmp     mostrarEstadisticas

ganaronOcas:
    mPuts   msgHanGanadoLasOcas

mostrarEstadisticas:
    mMostrarEstadisticas    msgIzq, qword[cantMovZorroIzq]
    mMostrarEstadisticas    msgDer, qword[cantMovZorroDer]
    mMostrarEstadisticas    msgArr, qword[cantMovZorroArr]
    mMostrarEstadisticas    msgAbj, qword[cantMovZorroAbj]
    mMostrarEstadisticas    msgArrIzq, qword[cantMovZorroArrIzq]
    mMostrarEstadisticas    msgArrDer, qword[cantMovZorroArrDer]
    mMostrarEstadisticas    msgAbjIzq, qword[cantMovZorroAbjIzq]
    mMostrarEstadisticas    msgAbjDer, qword[cantMovZorroAbjDer]
    jmp     fin

guardarPartida:
pedirNombreArchivoNuevaPartida:
    mPuts   msgPedirNombreNuevaPartida
    mImprimirPrompt
    mGets   nombreArchNuevaPartida

    mInterrumpirPartida byte[nombreArchNuevaPartida]

    sub     rsp,8
    call    validarNombreArchivo
    add     rsp,8

    cmp     byte[RESULTNOMBREARCH],'S'
    je      verSiYaExisteArchivoConEseNombre
    mPuts   msgNombreArchInvalido
    jmp     pedirNombreArchivoNuevaPartida

verSiYaExisteArchivoConEseNombre:
    mFopen  nombreArchNuevaPartida,modoAperturaArchLectura
    cmp     rax,0
    jle     crearNuevoArchivo
    mov     [fileHandlerNuevaPartida],rax
    mPuts   msgYaExiste
    mFclose qword[fileHandlerNuevaPartida]
    jmp     pedirNombreArchivoNuevaPartida

crearNuevoArchivo:
    mFopen  nombreArchNuevaPartida,modoAperturaArchEscritura
;   cmp     rax,0
;   jle     errorAperturaArchivoNuevaPartida
    mov     [fileHandlerNuevaPartida],rax
    mFwrite dataPartida,128,1,qword[fileHandlerNuevaPartida]
;   cmp     rax,1
;   jle     errorEscrituraArchivoNuevaPartida
    mFclose qword[fileHandlerNuevaPartida]
    mPuts   msgPartidaGuardada
    jmp     fin

interrupcionDePartida:
    mPuts   msgInterrupcionPartida

fin:
    ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RUTINAS INTERNAS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validarMovimientoZorro:
    mov     byte[RESULTMOVZORRO],'S'

    cmp     byte[movimientoZorro],'Q'   ; Arriba-Izq
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'W'   ; Arriba
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'E'   ; Arriba-Der
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'A'   ; Izq
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'S'   ; Abajo
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'D'   ; Der
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'Z'   ; Abajo-Izq
    je      movimientoZorroValido
    cmp     byte[movimientoZorro],'C'   ; Abajo-Der
    je      movimientoZorroValido

    mov     byte[RESULTMOVZORRO],'N'

movimientoZorroValido:
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validarOrientacion:
    mov     byte[RESULTORIENTACION],'S'

    cmp     byte[orientacionTablero],0      ; Sin orientación
    je      orientacionValida
    cmp     byte[orientacionTablero],'I'    ; Rotado 90° a Izq
    je      orientacionValida
    cmp     byte[orientacionTablero],'D'    ; Rotado 90° a Der
    je      orientacionValida
    cmp     byte[orientacionTablero],'V'    ; Rotado 180°
    je      orientacionValida

    mov     byte[RESULTORIENTACION],'N'
    
orientacionValida:
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validarMovimientoOca:

    mov     byte[RESULTMOVOCA],'S'

    mov     al,[movimientoOca]

    cmp     al,[movOcaCostado1]
    je      movimientoOcaValido

    cmp     al,[movOcaAdelante]
    je      movimientoOcaValido
    
    cmp     al,[movOcaCostado2]
    je      movimientoOcaValido

    mov     byte[RESULTMOVOCA],'N'

movimientoOcaValido:
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validarEleccion:
    mov     byte[RESULTELECCION],'S'

    cmp     byte[eleccionPartida],'s'
    je      eleccionValida

    cmp     byte[eleccionPartida],'n'
    je      eleccionValida

    mov     byte[RESULTELECCION],'N'

eleccionValida:
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validarNombreArchivo:
    mov     byte[RESULTNOMBREARCH],'N'

    mov     rdi,nombreArchNuevaPartida
    sub     rsp,8
    call    strlen
    add     rsp,8

    cmp     rax,5
    jl      invalido

    cmp     byte[nombreArchNuevaPartida + rax - 4],'.'
    jne     invalido
    cmp     byte[nombreArchNuevaPartida + rax - 3],'d'
    jne     invalido
    cmp     byte[nombreArchNuevaPartida + rax - 2],'a'
    jne     invalido
    cmp     byte[nombreArchNuevaPartida + rax - 1],'t'
    jne     invalido

    mov     byte[RESULTNOMBREARCH],'S'

invalido:
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;