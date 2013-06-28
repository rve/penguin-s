org 100h
jmp disp

msg: db "hello,world!",10
len: equ $ - msg

disp:
    mov ax, cs
    mov dx, ax
    mov es, ax

    mov ax, msg
    mov bp, ax
    mov cx, len
    mov ax, 1301h
    mov bx, 000ch
    mov dl, 0
    int 10h
    jmp $

