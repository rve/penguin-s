     org 100h                                       ; 程序加载到100h，可用于生成COM
 
; 设置时钟中断向量（08h），初始化段寄存器
        xor ax,ax                                               ; AX = 0
        mov es,ax                                       ; ES = 0
        mov word[es:20h],Timer          ; 设置时钟中断向量的偏移地址
        mov ax,cs
        mov [es:22h],ax                         ; 设置时钟中断向量的段地址=CS
        mov ds,ax                                       ; DS = CS
        mov es,ax                                       ; ES = CS
       
        mov     ax,0B800h                               ; 文本窗口显存起始地址
        mov     gs,ax                                   ; GS = B800h
        jmp $                                           ; 死循环
 
; 时钟中断处理程序
        delay EQU 1; 计时器延迟计数,用于控制画框的速度
        LENX EQU 80
        LENY EQU 25
        CYCLE EQU 13
        RIGHT EQU 1
        DOWN EQU 2
        LEFT EQU 3
        UP EQU 4
        count db delay                          ; 计时器计数变量，初值=delay
        x dw 0                      ; 当前行号
        y dw 0                      ; 当前列号
        endx dw 79
        endy dw 24
        dir db 1                   ; 当前画框的方向, 1-向右,2-向下,3-向左,4-向上
        char db 'A'                 ; 当前显示字符
        acc dw 0

       
Timer:
        dec byte [count]                         ; 递减计数变量
        jnz END_WALK                                         ; >0：跳转
WALK:
   ; circle limit
   mov ax, word [acc]
   cmp ax, CYCLE
   je END_WALK

    call SHOW

    mov bl, byte[dir] ; bx for dir
CHECK_RIGHT:
    cmp bl, RIGHT
    jne CHECK_DOWN
    mov cx, word [x]; cx for x
    cmp cx, word [endx]
    je .TO_DOWN
    inc word [x]
    jmp END_WALK
.TO_DOWN:
    mov byte [dir], DOWN
    jmp END_WALK

CHECK_DOWN:
    cmp bl, DOWN
    jne CHECK_LEFT
    mov cx, word [y] ; cx for y
    cmp cx, word [endy]
    je .TO_LEFT
    inc word [y]
    jmp END_WALK
.TO_LEFT:
    mov byte [dir], LEFT
    jmp END_WALK

CHECK_LEFT:
    cmp bl, LEFT
    jne CHECK_UP
    mov cx, word [x]; cx for x
    cmp cx, word [acc]
    je .TO_UP
    dec word [x]
    jmp END_WALK
.TO_UP:
    mov byte [dir], UP
    jmp END_WALK

CHECK_UP:
    cmp bl, UP
    jne END_WALK ; error handle 
    mov cx, word [y]; cx for y
    cmp cx, word [acc]
    je .TO_RIGHT
    dec word [y]
    jmp END_WALK
.TO_RIGHT:
    ; dir = RIGHT
    ; x = y = ++acc
    ; end[x,y] = LEN[X,Y] - acc -1
    ; ch ++
    mov byte [dir],RIGHT 
    inc byte [char]
    mov ax, word [acc]
    inc ax
    mov word [acc], ax
    mov word [x], ax
    mov word [y], ax
    mov bx, LENX - 1
    sub bx, ax
    mov word [endx], bx
    mov bx, LENY - 1
    sub bx, ax
    mov word [endy], bx
    jmp END_WALK
 
END_WALK:
        mov al,20h                                      ; AL = EOI
        out 20h,al                                              ; 发送EOI到主8529A
        out 0A0h,al                                     ; 发送EOI到从8529A
        iret                                                    ; 从中断返回
       
SHOW:
        xor ax,ax                      ; 计算当前字符的显存地址 gs:((80*x+y)*2)
        mov ax,word [y]
        mov bx,80                  
        mul bx
        add ax,word [x]            
        mov bx,2
        mul bx                  
        mov bp,ax
        mov ah,0Fh                 ; 0000：黑底、1111：亮白字（默认值为07h）
        mov al,byte[char]          ; AL = 显示字符值（默认值为20h=空格符）
        mov word[gs:bp],ax         ;   显示字符的ASCII码值
        mov byte[count],delay      ; 重置计数变量=初值delay
        ret
