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
        delay equ 1                                     ; 计时器延迟计数,用于控制画框的速度
        count db delay                          ; 计时器计数变量，初值=delay
        x dw 0                      ; 当前行号
        y dw 0                      ; 当前列号
        begin dw 0                                      ; 转圈次数
        enc dw 79                                       ; 列数上限
        enr dw 24                                       ; 行数上限
        dir db 1                   ; 当前画框的方向, 1-向右,2-向下,3-向左,4-向上
        char db 'A'                 ; 当前显示字符
       
Timer:
        dec byte[count]                         ; 递减计数变量
        jnz end                                         ; >0：跳转
       
right:
        mov al,byte[dir]           ;向右
        cmp al,1
        jnz down                                ;若方向不是向右,则转到向下
        mov ax,word[y]              
        cmp ax, word[enc]                       ;判断y是否等于上限
        jz righttodown                          ;等于上限则转到向下
        inc byte[y]
        jmp show       
 
righttodown:
        cmp word[begin], 12
        jz $ ;停在这里
        mov byte[dir],2           ;改为向下
        inc byte[x]
        jmp show
 
down:
        mov al,byte[dir]           ;向下
        cmp al,2
        jnz left                    ;若方向不是向下,则转到向左
        mov ax,word[x]              
        cmp ax, word[enr]                        ;判断x是否等于下限
        jz downtoleft               ;等于下限则转到向左
        inc byte[x]
        jmp show
 
downtoleft:
        mov byte[dir],3           ;改为向左
        dec byte[y]
        jmp show
 
left:
        mov al,byte[dir]           ;向左
        cmp al,3
        jnz up                  ;若方向不是向左,则转到向上
        mov ax,word[y]              
        cmp ax, word[begin]         ;判断y是否等于上限
        jz lefttoup                 ;等于上限则转到向上
        dec byte[y]
        jmp show
 
lefttoup:
        mov byte[dir],4           ;改为向上
        dec byte[x]
        jmp show
       
up:
        mov al,byte[dir]           ;向上
        cmp al,4
        jnz end                 ;若方向不是向上,则转到向右
        mov ax,word[x]              
        cmp ax, word[begin]              ;判断x是否等于上限
        jz uptoright                ;等于上限则转到向右
        dec byte[x]
        jmp show
 
uptoright:
        mov byte[dir],1           ; 改为向右
       
        inc byte[x]                        
        inc byte[y]                
        inc word[begin]                    
        dec word[enc]                      
        dec word[enr]
 
        mov al,byte[char]
        inc byte[char]
        jmp show
       
show:  
        xor ax,ax                      ; 计算当前字符的显存地址 gs:((80*x+y)*2)
        mov ax,word[x]
        mov bx,80                  
        mul bx
        add ax,word[y]            
        mov bx,2
        mul bx                  
        mov bp,ax
        mov ah,0Fh                 ; 0000：黑底、1111：亮白字（默认值为07h）
        mov al,byte[char]          ; AL = 显示字符值（默认值为20h=空格符）
        mov word[gs:bp],ax         ;   显示字符的ASCII码值
        mov byte[count],delay      ; 重置计数变量=初值delay
 
end:
        mov al,20h                                      ; AL = EOI
        out 20h,al                                              ; 发送EOI到主8529A
        out 0A0h,al                                     ; 发送EOI到从8529A
        iret                                                    ; 从中断返回
