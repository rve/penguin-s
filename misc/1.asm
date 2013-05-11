org 100h			; 可汇编成COM文件
	mov ax,0E801h	; 功能号
	int 15h			; 中断调用
	jc LB_fail		; 出错跳转
	push dx			; 保存DX
	push cx			; 保存CX
	push bx			; 保存BX
	call DispVal		; 显示AX
	pop ax			; 恢复BX
	call DispVal		; 显示BX
	pop ax			; 恢复CX
	call DispVal		; 显示CX
	pop ax			; 恢复DX
	call DispVal		; 显示DX
	ret	; 返回
LB_fail: ; 调用失败时显示“Failed!”字符串
	mov	bp,FailMsg	; BP=当前串的偏移地址
	mov	ax,ds		; ES:BP = 串地址
	mov	es,ax		; 置ES=DS
	mov	cx,7			; CX = 串长（=9）
	mov	ax,1301h		; AH = 13h（功能号）、AL = 01h（光标置于串尾）
	mov	bx,000Fh		; 页号为0(BH = 0) 黑底白字(BL = 0Fh)
	mov	dx,0			; 列号=0(DL=0) 行号=0(DH=0)
	int	10h			; 显示中断
	ret				; 退出程序
; 定义字符串常量	
	FailMsg: db "Failed!"	; 中断调用失败时显示的字符串
; 显示数据值十六进制串函数
DispVal: ; 显示16位整数值串（以AX为传递参数）
	mov dx,ax		; 保存传递参数AX的值
	; 显示高4位
	and ax,0F000h		; 取出最高的4位
	shr ax,12			; 右移12位
	call ShowChar		; 调用显示字符函数
	; 显示中高4位
	mov ax,dx		; 恢复传递参数AX的值
	and ax,0F00h		; 取出中高的4位
	shr ax,8			; 右移8位
	call ShowChar		; 调用显示字符函数
	; 显示中低4位
	mov ax,dx		; 恢复传递参数AX的值
	and ax,0F0h		; 取出中低的4位
	shr ax,4			; 右移4位
	call ShowChar		; 调用显示字符函数
	; 显示低4位
	mov ax,dx		; 恢复传递参数AX的值
	and ax,0Fh		; 取出最低的4位
	call ShowChar		; 调用显示字符函数
	; 显示空格符
	mov al,20h		; AL = 空格符
	mov ah,0Eh 		; 功能号（以电传方式显示单个字符）
	mov bl,0 		; 对文本方式置0
	int 10h 			; 调用10H号中断
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
