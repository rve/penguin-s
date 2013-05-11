        org 100h                                        ; 程序加载到100h，可用于生成COM
; 设置时钟中断向量（08h），初始化段寄存器
        xor ax,ax                                       ; AX = 0
        mov es,ax                               ; ES = 0
        mov word[es:20h],Timer  ; 设置时钟中断向量的偏移地址
        mov ax,cs
        mov [es:22h],ax                 ; 设置时钟中断向量的段地址=CS
        mov ds,ax                               ; DS = CS
        mov es,ax                               ; ES = CS
; 在屏幕顶行中央显示字符‘!’     
        mov     ax,0B800h                       ; 文本窗口显存起始地址
        mov     gs,ax                           ; GS = B800h
        mov ah,0Fh                              ; 0000：黑底、1111：亮白字（默认值为07h）
        mov al,'!'                                      ; AL = 显示字符值（默认值为20h=空格符）
        mov [gs:((80*0+39)*2)],ax       ; 屏幕第 0 行, 第 39 列
; 打开蜂鸣器
        mov al,0B6h                             ; 设控制字值
        out 43h,al                                      ; 写控制字到控制字寄存器
        in al,61h                                       ; 读8255B端口状态
        mov dl,al                                       ; 保存8255B端口的原状态值
        or al,3                                 ; 使状态值的低2位为1
        out 61h,al                                      ; 打开蜂鸣器
; 设置计数器
        call SetTimer                           ; 调用设置计数器函数
; 按任意键关闭蜂鸣器退出程序
        mov ah,0                                ; 功能号（读按键）
        int 16h                                         ; 调用16H号键盘中断
        mov al,dl                                       ; 恢复8255B端口的原状态值
        out 61h,al                                      ; 关闭蜂鸣器
        ret                                             ; 返回
 
; 时钟中断处理程序
        delay equ 100                           ; 计时器延迟计数
        count db delay                          ; 计时器计数变量，初值=delay
Timer: ; 时钟中断处理例程入口
        dec byte[count]                 ; 递减计数变量
        jnz end                                 ; >0：跳转
        inc byte[gs:((80*0+39)*2)]      ; =0：递增显示字符的ASCII码值
        mov byte[count],delay           ; 重置计数变量=初值delay
; 修改发声的频率
        mov al,byte[gs:((80*0+39)*2)]
        mov bl,50
        mul bl                                  ; AL*BL=>AX
        out 42h,al                                      ; 写计数器2的低字节
        mov al,ah                                       ; AL=AH
        out 42h,al                                      ; 写计数器2的高字节
end:
        mov al,20h                              ; AL = EOI
        out 20h,al                                      ; 发送EOI到主8529A
        out 0A0h,al                             ; 发送EOI到从8529A
        iret                                            ; 从中断返回
 
SetTimer:       ; 设置计数器函数
        mov al,34h                              ; 设控制字值
        out 43h,al                                      ; 写控制字到控制字寄存器
        mov ax,1193182/100              ; 每秒100次中断（10ms一次）
        out 40h,al                                      ; 写计数器0的低字节
        mov al,ah                                       ; AL=AH
        out 40h,al                                      ; 写计数器0的高字节
        ret
