;;
;; RAM  calculator  using E820h
;;
;; 0.01 show type 1 (available) ram
;; 0.02 print in natural way (convert little endian)
;;
org 100h			; 可汇编成COM文件
	;org 7C00h		; 用于引导扇区
	mov ax,cs		; DS = CS, SS = CS
	mov ds,ax
	mov ss,ax
	mov sp,100h-4	; 可汇编成COM文件
	;mov sp,7C00h-4	; 用于引导扇区

	mov es,ax		; ES = CS
	mov ebx,0		; EBX = 0 (初始值)
	mov di,Buf		; ES:DI = 返回值的缓冲区起始地址
LB_loop: ; 调用15h中断的E820h功能获取内存容量
	mov eax,0E820h		; 功能号
	mov ecx,20			; 缓冲区大小
	mov edx,534D4150h	; "SMAP" 校验标志
	int 15h				; 中断调用
	jc LB_fail			; 出错跳转
    push eax
    push ebx
	mov ah,byte[di+16]
	cmp ah,01
	jne LB_notsave


	add di,20				; 缓冲区指针后移20个字节
	inc word [Numb]		; 内存分段数加一
LB_notsave:
    pop ebx
    pop eax
	cmp ebx,0			; EBX = 0?
	jne LB_loop			; EBX != 0：继续调用
	mov di, Buf			; EBX = 0：结束，DI = 缓冲区起始地址（用于显示）
	jmp LB_OK			; 跳转到LB_OK，开始显示返回值

LB_fail: ; 调用失败时显示“Failed!”字符串
	mov	bp,FailMsg		; BP=当前串的偏移地址
	mov	ax,ds			; ES:BP = 串地址
	mov	es,ax			; 置ES=DS
	mov	cx,7				; CX = 串长（=9）
	mov	ax,1301h			; AH = 13h（功能号）、AL = 01h（光标置于串尾）
	mov	bx,000Fh			; 页号为0(BH = 0) 黑底白字(BL = 0Fh)
	mov	dx,0				; 列号=0(DL=0) 行号=0(DH=0)
	int	10h				; 显示中断
	mov word [Numb],0	; 置内存分段数=0（不显示返回值）
	ret					; 退出程序

LB_OK: ; 循环显示返回段值
	cmp word [Numb],0	; Numb = 0?
	je LB_out			; Numb = 0：退出程序
	mov cx,1			; CX = 20（行内循环初值）
LB_lloop: ; 行内循环
	call DispDword; 调用显示字节十六进制值的函数
	call DispDword; 调用显示字节十六进制值的函数
    call DispWord
	dec cx				; CX--
	jnz LB_lloop			; 行内循环
	dec word [Numb]		; Numb--
	call DispCrnl			; 回车换行
	jnz LB_OK			; 显示下一个内存段值
LB_out: ; 退出程序
	ret	; 返回

; 显示回车换行符
DispCrnl:
	mov al,0Ah		; AL = 换行符
	mov ah,0Eh 		; 功能号（以电传方式显示单个字符）
	mov bl,0 		; 对文本方式置0
	int 10h 			; 调用10H号中断
	mov al,0Dh		; AL = 回车符
	mov ah,0Eh 		; 功能号（以电传方式显示单个字符）
	mov bl,0 		; 对文本方式置0
	int 10h 			; 调用10H号中断
	ret

;dipaly one dword
DispDword:
    push ebp
    xor ebp, ebp
    mov bp, 8
LB_ddwloop:
    dec bp
    mov al, byte[di + bp]
    call DispByte
    jnz LB_ddwloop
    pop ebp
    add di,8
    ret
;diplay one word
DispWord:
    push ebp
    xor ebp, ebp
    mov bp, 4
LB_dwloop:
    dec bp
    mov al, byte[di + bp]
    call DispByte
    jnz LB_dwloop
    pop ebp
    add di,4
    ret


    
; 显示字节数据值十六进制串函数
DispByte: ; 显示字节数值串（以AL为传递参数）
	mov dl,al		; 保存传递参数AX的值
	; 显示高4位
	and al,0F0h	; 取出高4位
	shr al,4		; 右移4位
	call ShowChar	; 调用显示字符函数
	; 显示低4位
	mov al,dl		; 恢复传递参数AX的值
	and al,0Fh	; 取出低4位
	call ShowChar	; 调用显示字符函数
	; 显示空格符
	mov al,20h	; AL = 空格符
	mov ah,0Eh 	; 功能号（以电传方式显示单个字符）
	mov bl,0 	; 对文本方式置0
	int 10h 		; 调用10H号中断
	; 如果当前字节的序号%8=0，则多显示一个空格（分隔结构中的字段）
	mov ax,21	; AX = 21 - CX
	sub ax,cx
	and ax,7		; AX & 0111 b
	cmp ax,0		; AX % 8 = 0 ?
	jnz LB_ret	; != 0：返回、= 0：再显示一个空格符
	mov al,20h	; AL = 空格符
	mov ah,0Eh 	; 功能号（以电传方式显示单个字符）
	mov bl,0 	; 对文本方式置0
	int 10h 		; 调用10H号中断
LB_ret:
	ret

; 显示单个十六进制字符函数
ShowChar: ; 显示一个十六进制数字符：0~9、A~F（以AL为传递参数）
	cmp al,10		; AL < 10 ?
	jl digital		; AL < 10：跳转到digital
	add al,7		; AL >= 10：显示字母（ = 数值+=37h）
	digital:		; 数字
	add al,30h	; 数字字符 = 数值+=30h
	mov ah,0Eh 	; 功能号（以电传方式显示单个字符）
	mov bl,0 	; 对文本方式置0
	int 10h 		; 调用10H号中断
	ret

; 定义变量和缓冲区	
	Numb dw 0			; 内存分段数，初值=0
	FailMsg: db "Failed!"	; 中断调用失败时显示的字符串
	Buf: times 160 db 0		; 存放中断返回值的缓冲区
