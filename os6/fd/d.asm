        org 100h                ; 程序加载到100h，可用于生成COM
; 初始化段寄存器
        mov ax,cs
        mov     ds,ax                   ; DS = CS
        mov     es,ax                   ; ES = CS
        mov ss,ax                       ; SS = CS
        mov sp,100h-4           ; 堆栈基址
        mov     ax,0B800h               ; 文本窗口显存起始地址
        mov     gs,ax                   ; GS = B800h
ShowChar: ; 显示字符——程序的主循环
        mov al,'D'                      ; 设置要显示的字符
        call DispChar                   ; 调用显示字符函数
        mov dword [count],20000       ; 设置延时循环次数
        call delay                              ; 调用延时循环函数
        ; 下面这段代码在汇编成用于进程调度的a.bin时须修改成如下语句：
        jmp ShowChar                    ; 继续循环
        ; ----------------------------------------------------------------
        ; 有按任意键退出程序
        ; 检查是否有按键，无按键ZF=0，有按键ZF=1
        ;mov ah,1                       ; 功能号（是否有按键）
        ;int 16h                                ; 调用16H号键盘中断
        ;jz ShowChar                    ; 继续循环
        ;ret                                    ; 退出程序
        ; ------------------------------------------------------------------
DispChar: ; 显示字符函数
        mov ah,0Fh                      ; 0000：黑底、1111：亮白字（默认值为07h）
        mov bx,[CharPos]                ; 显存偏移地址
        mov [gs:bx],ax          ; 显示字符
        add word [CharPos],2    ; 文本屏幕下一个字符位
        ret
delay: ; 延时循环函数
        dec dword [count]               ; 递减循环计数
        jnz delay                               ; >0时继续循环
        ret                                     ; =0时返回
; 定义变量
        CharPos dw 80*2*22      ; 字符位置（起始于第3行第1列）
        count dd 1000000                ; 延时循环次数
