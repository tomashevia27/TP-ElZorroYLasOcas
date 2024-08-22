%macro mPuts 1
    mov     rdi,%1 ; const char *str
    sub     rsp,8
    call    puts
    add     rsp,8
%endmacro

%macro mPrintf 0
    sub     rsp,8
    call    printf
    add     rsp,8
%endmacro

%macro mSystem 1
    mov     rdi,%1 ; const char *command
    sub     rsp,8
    call    system
    add     rsp,8
%endmacro

%macro mGets 1
    mov     rdi,%1 ; char *buffer
    sub     rsp,8
    call    gets
    add     rsp,8
%endmacro

%macro mSscanf 0
    sub     rsp,8
    call    sscanf
    add     rsp,8
%endmacro

%macro mSprintf 0
    sub     rsp,8
    call    sprintf
    add     rsp,8
%endmacro

%macro mFopen 2
    mov     rdi,%1 ; char *fileName
    mov     rsi,%2 ; char *mode
    sub     rsp,8
    call    fopen
    add     rsp,8
%endmacro

%macro mFgets 3
    mov     rdi,%1 ; char *s
    mov     rsi,%2 ; int size
    mov     rdx,%3 ; FILE *fp
    sub     rsp,8
    call    fgets
    add     rsp,8
%endmacro

%macro mFread 4
    mov     rdi,%1 ; void *p
    mov     rsi,%2 ; int size
    mov     rdx,%3 ; int n
    mov     rcx,%4 ; FILE *fp
    sub     rsp,8
    call    fread
    add     rsp,8
%endmacro

%macro mFputs 2
    mov     rdi,%1 ; const char *s
    mov     rsi,%2 ; FILE *fp
    sub     rsp,8
    call    fputs
    add     rsp,8
%endmacro

%macro mFwrite 4
    mov     rdi,%1 ; void *p
    mov     rsi,%2 ; int size
    mov     rdx,%3 ; int n
    mov     rcx,%4 ; FILE *fp
    sub     rsp,8
    call    fwrite
    add     rsp,8
%endmacro

%macro mFclose 1
    mov     rdi,%1 ; FILE *fp
    sub     rsp,8
    call    fclose
    add     rsp,8
%endmacro

extern puts
extern printf
extern system
extern gets
extern sscanf
extern sprintf

extern fopen
extern fgets
extern fread
extern fputs
extern fwrite
extern fclose