
;%define	_BOOT_DEBUG_	; 用于生成.COM文件易于调试

%ifdef	_BOOT_DEBUG_
	org  100h			; 调试状态，做成 .COM 文件, 可调试
%else
	org  7c00h			; BIOS将把引导扇区加载到0:7C00处，并开始执行
%endif

;==============================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack		equ	100h	; 堆栈基地址(栈底, 从这个位置向低地址生长)
%else
BaseOfStack		equ	7c00h	; 堆栈基地址(栈底, 从这个位置向低地址生长)
%endif

BaseOfLoader		equ	9000h	; LOADER.BIN 被加载到的位置 ----  段地址
OffsetOfLoader	equ	100h	; LOADER.BIN 被加载到的位置 ---- 偏移地址
RootDirSectors	equ	32		; 根目录占用的扇区数
SectorNoOfRootDirectory	equ	269	; 根目录区的首扇区号
SectorNoOfFAT1	equ	253		; FAT#1的首扇区号 = BPB_RsvdSecCnt
DeltaSectorNo		equ	253		; DeltaSectorNo = BPB_RsvdSecCnt + 
							; (BPB_NumFATs * FATSz) - 2 = 253 + (2*8) -2*8 = 253
							; 文件的开始扇区号 = 目录条目中的开始扇区号 
							; + 根目录占用扇区数目 + DeltaSectorNo
;==============================================================
    jmp short LABEL_START		; 引导开始，跳转指令
	nop							; 这个 nop 不可少，无操作，占字节位
	
LABEL_START:
	mov	ax, cs	; 置其他段寄存器值与CS相同
	mov	ds, ax	; 数据段
	mov	es, ax	; 附加段
	mov	ss, ax	; 堆栈段
	mov	sp, BaseOfStack ; 堆栈基址

; 清屏
	mov	ax, 600h		; AH = 6（功能号）、AL = 0（滚动文本行数，0为整个窗口）
	mov	bh, 7		; 黑底白字
	mov	cx, 0			; 左上角：(0, 0)
	mov	dx, 184fh		; 右下角：(24, 79)
	int	10h			; 显示中断

	mov	dh, 0		; "Booting  "
	call	DispStr		; 显示字符串

; 软驱复位
	xor	ah, ah	; 功能号ah=0（复位磁盘驱动器）
	mov	dl, 80h	; dl=80h（软驱，硬盘和U盘为80h）
	int	13h		; 磁盘中断
	
; 下面在A盘根目录中寻找 LOADER.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory 	; 给表示当前扇区号的
						; 变量wSectorNo赋初值为根目录区的首扇区号（=19）
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; 判断根目录区是否已读完
	jz	LABEL_NO_LOADERBIN		; 若读完则表示未找到LOADER.BIN
	dec	word [wRootDirSizeForLoop]	; 递减变量wRootDirSizeForLoop的值
	; 调用读扇区函数读入一个根目录扇区到装载区
	mov	ax, BaseOfLoader
	mov	es, ax			; ES <- BaseOfLoader（9000h）
	mov	bx, OffsetOfLoader	; BX <- OffsetOfLoader（100h）
	mov	ax, [wSectorNo]	; AX <- 根目录中的当前扇区号
	mov	cl, 1				; 只读一个扇区
	call	ReadSector		; 调用读扇区函数

	mov	si, LoaderFileName	; DS:SI -> "LOADER  BIN"
	mov	di, OffsetOfLoader	; ES:DI -> BaseOfLoader:0100
	cld					; 清除DF标志位
						; 置比较字符串时的方向为左/上[索引增加]
	mov	dx, 16			; 循环次数=16（每个扇区有16个文件条目：512/32=16）
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0				; 循环次数控制
	jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR ; 若已读完一扇区
	dec	dx				; 递减循环次数值			  就跳到下一扇区
	mov	cx, 11			; 初始循环次数为11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND	; 如果比较了11个字符都相等，表示找到
	dec	cx				; 递减循环次数值
	lodsb				; DS:SI -> AL（装入字符串字节）
	cmp	al, byte [es:di]		; 比较字符串的当前字符
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT	; 只要发现不一样的字符就表明本DirectoryEntry
							; 不是我们要找的LOADER.BIN
LABEL_GO_ON:
	inc	di					; 递增DI
	jmp	LABEL_CMP_FILENAME	; 继续循环

LABEL_DIFFERENT:
	and	di, 0FFE0h		; DI &= E0为了让它指向本条目开头（低5位清零）
					; FFE0h = 1111111111100000（低5位=32=目录条目大小）
	add	di, 20h			; DI += 20h 下一个目录条目
	mov	si, LoaderFileName	; SI指向装载文件名串的起始地址
	jmp	LABEL_SEARCH_FOR_LOADERBIN; 转到循环开始处

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1 ; 递增当前扇区号
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2		; "No LOADER"
	call	DispStr		; 显示字符串
%ifdef	_BOOT_DEBUG_ ; 没有找到LOADER.BIN就回到 DOS
	mov	ax, 4c00h		; AH=4Ch（功能号，终止进程）、AL=0（返回代码）
	int	21h			; DOS软中断
%else
	jmp	$			; 没有找到 LOADER.BIN，在这里进入死循环
%endif

LABEL_FILENAME_FOUND:	; 找到 LOADER.BIN 后便来到这里继续,计算出簇号N所对应的装载文件的扇区号（=N+299）
	mov	ax, RootDirSectors	; AX=根目录占用的扇区数
	and	di, 0FFE0h		; DI -> 当前条目的开始地址
	add	di, 1Ah			; DI -> 文件的开始簇号在条目中的偏移地址
	mov cx, word [es:di]	; CX=文件的开始簇号,若找到相等的文件条目，从该条目获取起始簇号N
	push cx				; 保存此扇区在FAT中的序号
	shl cx, 3
	add	cx, ax			; CX=文件的相对起始扇区号+根目录占用的扇区数
	add	cx, DeltaSectorNo	; CL <- LOADER.BIN的起始扇区号(0-based)
	mov	ax, BaseOfLoader
	mov	es, ax			; ES <- BaseOfLoader（装载程序基址=9000h）
	mov	bx, OffsetOfLoader	; BX <- OffsetOfLoader（装载程序偏移地址=100h）
	mov	ax, cx			; AX <- 起始扇区号

;读文件内部扇区的预处理
LABEL_GOON_LOADING_FILE:
	push bx				; 保存装载程序偏移地址
	mov	cl, 8				; 1个簇=8个扇区
	call	ReadSector		;调用读扇区函数将装载文件的当前簇读到内存中加载地址的当前扇区

; 每读一个簇就在 "Booting  " 后面打一个点, 形成这样的效果：Booting ......
	mov	ah, 0Eh		; 功能号（以电传方式显示单个字符）
	mov	al, '.'			; 要显示的字符
	mov	bl, 0Fh		; 黑底白字
	int	10h			; 显示中断

	; 计算文件的下一簇的起始扇区号，跳转结束或者读下一个簇
	pop bx				; 取出装载程序偏移地址
	pop	ax				; 取出此扇区在FAT中的序号
	call	GetFATEntry		; 获取FAT项中的下一簇号,由当前簇号值N计算其对应FAT项在FAT表中的偏移地址D（=N*1.5B），由D值计算出FAT项所在扇区的序号K（=1+D/512）和偏移值O（=D%512）
	cmp	ax, 0FF8h		;利用偏移值O获取FAT项值N（=文件下一个簇的序号）,是否是文件最后簇
	jae	LABEL_FILE_LOADED	;若N>=FF8h，则文件已经读完，跳转到装载程序
	push ax				; 保存扇区在FAT中的序号
	shl ax, 3
	mov	dx, RootDirSectors	; DX = 根目录扇区数 = 32
	add	ax, dx			; 扇区序号 + 根目录扇区数
	add	ax, DeltaSectorNo		; AX = 要读的数据扇区地址,计算出簇号N所对应的装载文件的扇区号（=N+299）
	add	bx, 1000h	; BX+512*8指向装载程序区的下一个扇区地址
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
	mov	dh, 1			; "Ready."
	call	DispStr			; 显示字符串

; **********************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; 这一句正式跳转到已加载到内
						; 存中的 LOADER.BIN 的开始处，
						; 开始执行 LOADER.BIN 的代码。
						; Boot Sector 的使命到此结束
; **********************************************************************

;==============================================================
;变量
wRootDirSizeForLoop	dw	32	; 根目录区剩余扇区数
										; 初始化为32，在循环中会递减至零
wSectorNo		dw	0	; 当前扇区号，初始化为0，在循环中会递增
bOdd			db	0	; 奇数还是偶数FAT项

;字符串
LoaderFileName	db	"LOADER  BIN", 0 ; LOADER.BIN之文件名
; 为简化代码，下面每个字符串的长度均为MessageLength（=9），似串数组
MessageLength	    equ	 9
BootMessage:		db	"Booting  " 	; 9字节，不够则用空格补齐。序号0
Message1			db	"Ready.   " 	; 9字节，不够则用空格补齐。序号1
Message2			db	"No LOADER" ; 9字节，不够则用空格补齐。序号2
;==============================================================

;----------------------------------------------------------------------------
; 函数名：DispStr
;----------------------------------------------------------------------------
; 作用：显示一个字符串，函数开始时DH中须为串序号(0-based)
DispStr:
	mov	ax, MessageLength ; 串长->AX（即AL=9）
	mul	dh				; AL*DH（串序号）->AX（=当前串的相对地址）
	add	ax, BootMessage	; AX+串数组的起始地址
	mov	bp, ax			; BP=当前串的偏移地址
	mov	ax, ds			; ES:BP = 串地址
	mov	es, ax			; 置ES=DS
	mov	cx, MessageLength	; CX = 串长（=9）
	mov	ax, 1301h			; AH = 13h（功能号）、AL = 01h（光标置于串尾）
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0				; 列号=0
	int	10h				; 显示中断
	ret					; 函数返回
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; 函数名：ReadSector
;----------------------------------------------------------------------------
; 作用：从第 AX个扇区开始，将CL个扇区读入ES:BX中
ReadSector:
	; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号->柱面号、起始扇区、磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 2（4个磁头）
	;       x           ┌ 商 y ┤
	;   -------------- 	=> ┤      └ 磁头号 = y & 3
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push bp		; 保存BP
	mov bp, sp	; 让BP=SP
	sub	sp, 2 	; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]
	mov	byte [bp-2], cl	; 压CL入栈（保存表示读入扇区数的传递参数）
	push bx			; 保存BX
	mov	bl, 63	; BL=63（磁道扇区数）为除数
	div	bl			; AX/BL，商y在AL中、余数z在AH中
	inc	ah			; z ++（因磁盘的起始扇区号为1）
	mov	cl, ah		; CL <- 起始扇区号
	mov	dh, al		; DH <- y
	shr	al, 2			; y >> 2 （等价于y/BPB_NumHeads，硬盘有4个磁头）
	mov	ch, al		; CH <- 柱面号
	and	dh, 3		; DH & 3 = 磁头号
	pop	bx			; 恢复BX
	; 至此，"柱面号、起始扇区、磁头号"已全部得到
	mov	dl, 80h	; 驱动器号（0表示软盘A）
.GoOnReading: ; 使用磁盘中断读入扇区
	mov	ah, 2				; 功能号（读扇区）
	mov	al, byte [bp-2]		; 读AL个扇区
	int	13h				; 磁盘中断
	jc	.GoOnReading	; 如果读取错误，CF会被置为1，
						; 这时就不停地读，直到正确为止
	add	sp, 2				; 栈指针+2
	pop	bp				; 恢复BP

	ret
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; 函数名：GetFATEntry
;----------------------------------------------------------------------------
; 作用：找到序号为AX的扇区在FAT中的条目，结果放在AX中。需要注意的
;     是，中间需要读FAT的扇区到ES:BX处，所以函数一开始保存了ES和BX
GetFATEntry:
	push es			; 保存ES、BX和AX（入栈）
	push bx
	push ax
; 设置读入的FAT扇区写入的基地址
	mov ax, BaseOfLoader	; AX=9000h
	sub	ax, 100h		; 在BaseOfLoader后面留出4K空间用于存放FAT
	mov	es, ax		; ES=8F00h
; 判断FAT项的奇偶
	pop	ax			; 取出FAT项序号（出栈）
	mov	byte [bOdd], 0; 初始化奇偶变量值为0（偶）
	mov	bx, 3		; AX*1.5 = (AX*3)/2
	mul	bx			; DX:AX = AX * 3（AX*BX 的结果值放入DX:AX中）
	mov	bx, 2		; BX = 2（除数）
	xor	dx, dx		; DX=0	
	div	bx			; DX:AX / 2 => AX <- 商、DX <- 余数
	cmp	dx, 0		; 余数 = 0（偶数）？
	jz LABEL_EVEN	; 偶数跳转
	mov	byte [bOdd], 1	; 奇数
LABEL_EVEN:		; 偶数
	; 现在AX中是FAT项在FAT中的偏移量，下面来
	; 计算FAT项在哪个扇区中(FAT占用不止一个扇区)
	xor	dx, dx		; DX=0	
	mov	bx, 512		; BX=512
	div	bx			; DX:AX / 512
		  			; AX <- 商 (FAT项所在的扇区相对于FAT的扇区号)
		  			; DX <- 余数 (FAT项在扇区内的偏移)
	push dx			; 保存余数（入栈）
	mov bx, 0 		; BX <- 0 于是，ES:BX = 8F00h:0
	add	ax, SectorNoOfFAT1 ; 此句之后的AX就是FAT项所在的扇区号
	mov	cl, 2			; 读取FAT项所在的扇区，一次读两个，避免在边界
	call	ReadSector	; 发生错误, 因为一个 FAT项可能跨越两个扇区,调用读扇区函数将磁盘的（FAT表中的）K号和K+1号两个扇区（因为一个 FAT项可能跨越两个扇区）读入内存缓冲区（8F000h）
	pop	dx			; DX= FAT项在扇区内的偏移（出栈）
	add	bx, dx		; BX= FAT项在扇区内的偏移
	mov	ax, [es:bx]	; AX= FAT项值
	cmp	byte [bOdd], 1	; 是否为奇数项？
	jnz	LABEL_EVEN_2	; 偶数跳转
	shr	ax, 4			; 奇数：右移4位（取高12位）
LABEL_EVEN_2:		; 偶数
	and	ax, 0FFFh	; 取低12位
LABEL_GET_FAT_ENRY_OK:
	pop	bx			; 恢复ES、BX（出栈）
	pop	es
	ret

;----------------------------------------------------------------------------

times 446-($-$$) db 0	; 用0填充剩下的扇区空间
;下面是磁盘分区的首个表项（起始地址为446）
DPT_Active         DB 0     ;是否激活
DPT_FirHead        DB 0     ;开始磁头号
DPT_FirSection     DW 1     ;开始扇区号
DPT_SubMode        DB 1     ;分区类型
DPT_EndHead        DB 3    ;结束磁头号
DPT_EndSection     DB 63    ;结束扇区号
DPT_EndCylinder    DB 79    ;结束柱面号
DPT_FirLBA         DD 252     ;分区起始地址逻辑地址块值
DPT_Volume         DD 20160 ;分区大小
times 510-($-$$) db 0	; 用0填充剩下的扇区空间
db 	55h, 0aah			; 引导扇区结束标志

times 512*63*4-($-$$) db 0	; 用0填充0号柱面剩下的扇区空间

    jmp short LABEL_START_O		; 引导开始，跳转指令
	nop							; 这个 nop 不可少，无操作，占字节位

	BS_OEMName	    DB 'MyOS-LCW'	; OEM串，必须8个字节，不足补空格
; 下面是 FAT12 磁盘的头
	BPB_BytsPerSec	DW 512		; 每扇区字节数
	BPB_SecPerClus	DB 8		; 每簇扇区数
	BPB_RsvdSecCnt	DW 1		; Boot记录占用扇区数
	BPB_NumFATs  	DB 2		; FAT表数
	BPB_RootEntCnt	DW 512		; 根目录文件数最大值
	BPB_TotSec16	DW 20160	; 逻辑扇区总数
	BPB_Media		DB 0F8h		; 介质描述符
	BPB_FATSz16	    DW 8		; 每FAT扇区数
	BPB_SecPerTrk	DW 63		; 每磁道扇区数
	BPB_NumHeads	DW 4		; 磁头数(面数)
	BPB_HiddSec	    DD 0		; 隐藏扇区数
	BPB_TotSec32	DD 0		; BPB_TotSec16为0时由此值记录扇区总数
	BS_DrvNum		DB 80h		; 中断 13 的驱动器号（软盘）
	BS_Reserved1	DB 0		; 未使用
	BS_BootSig		DB 29h		; 扩展引导标记 (29h)
	BS_VolID		DD 23456789h		; 卷序列号
	BS_VolLab		DB 'MyOS System'; 卷标，必须11个字节，不足补空格
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型，必须8个字节，不足补空格
	
	LABEL_START_O:
	
times 129534-($-$$) db 0	; 用0填充1号柱面1号扇区剩下的扇区空间
db 	55h, 0aah			; 分区引导扇区结束标志	
; 填充两个FAT表的头两个项（每个FAT占8个扇区）
	db 0f8h, 0ffh, 0ffh			; 介质描述符（F0h）和Fh、结束簇标志项FFFh
	times 512*8-3		db	0	; 用0填充FAT#1剩下的空间
	db 0f8h, 0ffh, 0ffh			; 介质描述符（F0h）和Fh、结束簇标志项FFFh
	times 512*8-3		db	0	; 用0填充FAT#2剩下的空间
; 根目录中的卷标条目
	db 'MyOS System' 			; 卷标, 必须 11 个字节（不足补空格）
	db 8						; 文件属性值（卷标条目的为08h）
	dw 0,0,0,0,0				; 10个保留字节
	dw 0,426Eh				; 创建时间，设为2013年3月14日0时0分0秒
	dw 0						; 开始簇号（卷标条目的必需为0）
	dd 0						; 文件大小（也设为0）
