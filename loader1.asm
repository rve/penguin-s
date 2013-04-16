	org	0100h		; 可用于生成调试用的COM文件
	mov	ax, 0B800h	; 文本窗口所对应的显存起始地址
	mov	gs, ax		; GS是80386 CPU新增加的一个附加段寄存器
	mov	ah, 0Fh		; AH = 字符属性质，0000：黑底、1111：白字
	mov	al, 'L'		; AL = 字符的ASCII码
	mov	[gs:((80 * 0 + 39) * 2)], ax	; 屏幕第 0 行, 第 39 列
	jmp	LABEL_SHOW_O
	times 512-($-$$)	db	0		; 用0填充扇区剩余空间
LABEL_SHOW_O:
	mov	al, 'O'
	mov	[gs:((80 * 1 + 39) * 2)], ax	; 屏幕第 1 行, 第 39 列
	jmp	LABEL_SHOW_A
	times 2*512-($-$$)	db	0		; 用0填充扇区剩余空间
LABEL_SHOW_A:
	mov	al, 'A'
	mov	[gs:((80 * 2 + 39) * 2)], ax	; 屏幕第 2 行, 第 39 列
	jmp	LABEL_SHOW_D
	times 3*512-($-$$)	db	0		; 用0填充扇区剩余空间
LABEL_SHOW_D:
	mov	al, 'D'
	mov	[gs:((80 * 3 + 39) * 2)], ax	; 屏幕第 3 行, 第 39 列
	jmp	LABEL_SHOW_OS_O
	times 4*512-($-$$)	db	0		; 用0填充扇区剩余空间							
LABEL_SHOW_OS_O:
	mov	al, 'O'
	mov	[gs:((80 * 4 + 39) * 2)], ax	; 屏幕第 4 行, 第 39 列
	jmp	LABEL_SHOW_OS_S
	times 5*512-($-$$)	db	0		; 用0填充扇区剩余空间
LABEL_SHOW_OS_S:
	mov	al, 'S'
	mov	[gs:((80 * 5 + 39) * 2)], ax	; 屏幕第 5 行, 第 39 列
	jmp $		; 到此停住，进入死循环
