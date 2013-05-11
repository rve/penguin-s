mt
%include	"pm.inc"	; 常量, 宏, 以及一些说明

org 100h	
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT（定义全局描述符表）
;                       		   段基址,  段界限,  属性
LABEL_GDT: 		  Descriptor 0,       0, 		 0   	; 空描述符
LABEL_DESC_CODE32: Descriptor 0, SegCode32Len - 1, DA_C + DA_32; 非一致代码段
LABEL_DESC_VIDEO:  Descriptor 0B8000h, 0ffffh,  DA_DRW	; 显存首地址
; GDT 结束

; 定义48位的GDT参数结构GdtPtr（16位界限 + 32位基地址）
GdtLen	equ	$ - LABEL_GDT	; GDT长度
GdtPtr	dw	GdtLen - 1		; GDT界限
		dd	0				; GDT基地址

; GDT 选择符（定义代码段和显存段在GDT中的偏移量）
SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs	; 设置DS/ES/SS = CS
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 100h	; 设置 SP = 100h

	; 初始化 32 位代码段描述符
	xor	eax, eax	; EAX = 0
	mov	ax, cs
	shl	eax, 4	; EAX = 代码段基址
	add	eax, LABEL_SEG_CODE32	; EAX += 偏移地址 = 代码段地址
	mov	word [LABEL_DESC_CODE32 + 2], ax	; B0~15 = AX
	shr	eax, 16	; EAX >> 16（AX = EAX的高16位）
	mov	byte [LABEL_DESC_CODE32 + 4], al		; B16~23 = AL
	mov	byte [LABEL_DESC_CODE32 + 7], ah	; B24~31 = AH

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <-- GDT基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <-- GDT基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b ; or al, 2（关闭：and al,0FDh）
	out	92h, al

	; 准备切换到保护模式（置CR0的PE位为1）
	mov	eax, cr0
	or	eax, 1	; PE = 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs,
							; 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择符(目的)

	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax

	; 到此停止
	jmp	$	; 死循环

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]
	times 510-($-$$) db 0	;
	db 55h, 0aah
