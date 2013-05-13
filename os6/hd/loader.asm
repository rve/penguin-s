org  100h			; 用于生成.COM 文件
;==============================================================
; 定义常量
BaseOfStack		equ	100h	; 堆栈基地址(栈底, 从这个位置向低地址生长)
BaseOfBuf		equ 8800h	; 用于查找文件条目的缓冲区 ---- 基地址
OffsetOfBuf		equ	0		; 用于查找文件条目的缓冲区 ---- 偏移地址
OffsetOfFile		equ	100h	; 文件被加载到的位置 ---- 偏移地址
RootDirSectors	equ	32		; 根目录占用的扇区数
SectorNoOfRootDirectory	equ	269	; 根目录区的首扇区号
SectorNoOfFAT1	equ	253	; FAT1 的第一个扇区号 = BPB_RsvdSecCnt
DeltaSectorNo	equ	253		; DeltaSectorNo = BPB_RsvdSecCnt + 
							; (BPB_NumFATs * FATSz) - 2
							; 文件的开始扇区号 = DirEntry中的开始扇区号 
							; + 根目录占用扇区数目 + DeltaSectorNo
;==============================================================
LABEL_START:
	mov	ax, cs	; 置其他段寄存器值与CS相同
	mov	ds, ax	; 数据段
	mov	es, ax	; 附加段
	mov	ss, ax	; 堆栈段
	mov	sp, BaseOfStack ; 堆栈基址
; 清屏
	mov	ax, 600h	; AH = 6,  AL = 0
	mov	bx, 700h	; 黑底白字(BL = 7)
	mov	cx, 0		; 左上角: (0, 0)
	mov	dx, 184fh	; 右下角: (24, 79)
	int	10h		; 显示中断

; 下面在A盘根目录中寻找 *.BIN
LABEL_REPEAT:			; 装载文件循环，循环变量为count = 0~4
	mov	dh, byte [count] 	; "Loader *"
	call DispStr			; 显示字符串
	mov word [wRootDirSizeForLoop], RootDirSectors	; 初始化
	mov	word [wSectorNo], SectorNoOfRootDirectory 	; 给表示当前扇区号的
						; 变量wSectorNo赋初值为根目录区的首扇区号（=19）
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; 判断根目录区是否已读完
	jz	LABEL_NO_LOADERBIN		; 若读完则表示未找到LOADER.BIN
	dec	word [wRootDirSizeForLoop]	; 递减变量wRootDirSizeForLoop的值
	mov	ax, BaseOfBuf
	mov	es, ax			; ES <- BaseOfBuf
	mov	bx, OffsetOfBuf	; BX <- OffsetOfBuf
	mov	ax, [wSectorNo]	; AX <- 根目录中的某Sector号
	mov	cl, 1				; 只读一个扇区
	call ReadSector		; 调用读扇区函数
	mov al, byte [count]
	mov bl, 11
	mul bl
	add ax, FileName
	mov	si, ax 		; DS:SI -> 要装入的文件名串地址=FileName+11*[count]
	mov	di, OffsetOfBuf	; ES:DI -> BaseOfBuf:0
	cld					; 清除DF标志位
						; 置比较字符串时的方向为左/上[索引增加]
	mov	dx, 10h			; 循环次数=16（每个扇区有16个文件条目：512/32=16）
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0			; 循环次数控制
	jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR ; 若已读完一扇区
	dec	dx				; 递减循环次数值			  就跳到下一扇区
	mov	cx, 11			; 初始循环次数为11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND; 如果比较了11个字符都相等，表示找到
	dec	cx				; 递减循环次数值
	lodsb				; DS:SI -> AL（装入字符串字节）
	cmp	al, byte [es:di]; 比较字符串的当前字符
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT	; 只要发现不一样的字符就表明本文件条目
							; 不是我们要找的文件名串
LABEL_GO_ON:
	inc	di					; 递增DI
	jmp	LABEL_CMP_FILENAME	; 继续循环
LABEL_DIFFERENT:
	and	di, 0FFE0h	; DI &= E0为了让它指向本条目开头（低5位清零）
					; FFE0h = 1111111111100000（低5位=32=目录条目大小）
	add	di, 20h		; DI += 20h 下一个目录条目
	mov al, byte [count]
	mov bl, 11
	mul bl
	add ax, FileName
	mov	si, ax 		; DS:SI -> 要装入的文件名串地址=FileName+11*[count]
	jmp	LABEL_SEARCH_FOR_LOADERBIN; 转到循环开始处
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1 ; 递增扇区号
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN
LABEL_NO_LOADERBIN:
	mov	dh, 5		; "Not found"
	call DispStr		; 显示字符串
	; 没有找到文件，按任意键退出
	mov ah,0 		; 功能号（读按键）
	int 16h 			; 调用16H号键盘中断
	ret				; 返回
LABEL_FILENAME_FOUND:	; 找到 LOADER.BIN 后便来到这里继续
	mov	ax, RootDirSectors	; AX=根目录占用的扇区数
	and	di, 0FFE0h	; DI -> 当前条目的开始
	add	di, 1Ah		; DI -> 文件的首扇区号在条目中的偏移地址
	mov	cx, word [es:di]
	push	cx			; 保存此扇区在FAT中的序号
	shl cx,3
	add	cx, ax		; CX=文件的相对起始扇区号+根目录占用的扇区数
	add	cx, DeltaSectorNo	; CL <- 文件的起始扇区号(0-based)
	mov bl, byte [count]
	mov bh,0
	shl bx,1
	add bx, BaseOfFile
	mov ax, [bx]
	mov	es, ax			; ES <- BaseOfFile = [baseOfFile + 2*[count]]
	mov	bx, OffsetOfFile	; BX <- OffsetOfFile（被装载程序偏移地址）
	mov	ax, cx			; AX <- 扇区号
LABEL_GOON_LOADING_FILE:
	mov	cl, 8		; 1个扇区
	call ReadSector	; 读扇区
	pop	ax			; 取出此扇区在FAT中的序号
	call GetFATEntry
	cmp	ax, 0FF8h	; 是否是文件最后簇
	jae LABEL_FILE_LOADED	; ≥FF8h时跳转，否则读下一个簇
	push ax			; 保存扇区在FAT中的序号
	shl ax,3
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo	; AX = 要读的数据扇区地址
	add	bx, 512*8; BX+512*8指向装载程序区的下一个扇区地址
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
	inc byte [count]
	cmp byte [count], 5
	jnz LABEL_REPEAT
	mov dh, 6		; "Load finish"
	call DispStr		; 显示字符串

; **********************************************************************
	jmp	4000h:OffsetOfFile	; 这一句正式跳转到已加载到内
						; 存中的 KERNEL.BIN 的开始处，
						; 开始执行 KERNEL.BIN 的代码。
						; LOADER.BIN 的使命到此结束
; **********************************************************************

;==============================================================
;变量
wRootDirSizeForLoop	dw	RootDirSectors	; 根目录占用的扇区数，
										; 在循环中会递减至零
BPB_BytsPerSec	DW 512		; 每扇区字节数
BPB_SecPerTrk	DW 63	; 每磁道扇区数
BS_DrvNum		DB 80h	; 中断 13 的驱动器号（硬盘）
wSectorNo	dw	0	; 要读取的扇区数
bOdd		db	0	; 奇数还是偶数
count		db	0	; 已装入的文件数（循环变量）
BaseOfFile: dw 4000h, 6000h, 7000h, 8000h,5000h ; 内核与进程A、B、C,D的内存基地址
; 文件名字符串
FileName:	db	"KERNEL  BIN" ; KERNEL.BIN文件名
FileName1	db	"A       BIN" ; A.BIN文件名
FileName2	db	"B       BIN" ; B.BIN文件名
FileName3	db	"C       BIN" ; C.BIN文件名
FileName4	db	"D       BIN" ; D.BIN文件名
; 为简化代码，下面每个字符串的长度均为MessageLength（=11），似串数组
MessageLength		equ	11
BootMessage:		db	"Load Kernel" 	; 11字节，不够则用空格补齐。序号0
Message1			db	"Load Proc A" 	; 11字节，不够则用空格补齐。序号1
Message2			db	"Load Proc B" 	; 11字节，不够则用空格补齐。序号2
Message3			db	"Load Proc C" 	; 11字节，不够则用空格补齐。序号3
Message4			db	"Load Proc D" 	; 11字节，不够则用空格补齐。序号4
Message5			db	"Not found! "		; 11字节，不够则用空格补齐。序号5
Message6			db	"Load finish"		; 11字节，不够则用空格补齐。序号6
;==============================================================

;----------------------------------------------------------------------------
; 函数名：DispStr
;----------------------------------------------------------------------------
; 作用：显示一个字符串，函数开始时DH中须为串序号(0-based)
DispStr:
	mov	ax, MessageLength ; 串长->AX（即AL=11）
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
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	;   -------------- 	=> ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push bp
	mov	bp, sp
	sub	sp, 2 		; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]
	mov	byte [bp-2], cl
	push bx			; 保存BX
	mov	bl, [BPB_SecPerTrk]	; BL为除数
	div	bl			; AX/BL，商y在AL中、余数z在AH中
	inc	ah			; z ++（因磁盘的起始扇区号为1）
	mov	cl, ah		; CL <- 起始扇区号
	mov	dh, al		; DH <- y
	shr	al, 2			; y >> 1 （等价于y/BPB_NumHeads，硬盘有4个磁头）
	mov	ch, al		; CH <- 柱面号
	and	dh, 3		; DH & 3 = 磁头号
	pop	bx			; 恢复BX
	; 至此，"柱面号、起始扇区、磁头号"已全部得到
	mov	dl, [BS_DrvNum]	; 驱动器号（0表示软盘A）
.GoOnReading:
	mov	ah, 2			; 读扇区
	mov	al, byte [bp-2]	; 读AL个扇区
	int	13h			; 磁盘中断
	jc	.GoOnReading; 如果读取错误，CF会被置为1，
					; 这时就不停地读，直到正确为止
	add	sp, 2			; 栈指针+2
	pop	bp

	ret
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; 函数名：GetFATEntry
;----------------------------------------------------------------------------
; 作用：找到序号为AX的扇区在FAT中的条目，结果放在AX中。需要注意的
;     是，中间需要读FAT的扇区到ES:BX处，所以函数一开始保存了ES和BX
GetFATEntry:
	push	es	; ES、BX和AX入栈
	push	bx
	push	ax
	mov	ax, 9000h
	sub	ax, 40h		; 在BaseOfLoader后面留出1K空间用于存放FAT
	mov	es, ax		; ES=8FC0h
; 判断FAT项的奇偶
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; DX:AX = AX * 3（AX*BX 的结果值放入DX:AX中）
	mov	bx, 2
	xor	dx, dx		; DX=0	
	div	bx			; DX:AX / 2 => AX <- 商、DX <- 余数
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1	; 奇数
LABEL_EVEN:				; 偶数
	; 现在AX中是FAT项在FAT中的偏移量，下面来
	; 计算FAT项在哪个扇区中(FAT占用不止一个扇区)
	xor	dx, dx				; DX=0	
	mov	bx, [BPB_BytsPerSec]	; BX=512
	div	bx	; DX:AX / 512
		  	; AX <- 商 (FAT项所在的扇区相对于FAT的扇区号)
		  	; DX <- 余数 (FAT项在扇区内的偏移)
	push	dx	; 保存余数
	mov	bx, 0 ; BX <- 0 于是，ES:BX = (BaseOfLoader – 1000h):0
	add	ax, SectorNoOfFAT1 ; 此句之后的AX就是FAT项所在的扇区号
	mov	cl, 2			; 读取FAT项所在的扇区，一次读两个，避免在边界
	call	ReadSector	; 发生错误, 因为一个 FAT项可能跨越两个扇区
	pop	dx			; DX= FAT项在扇区内的偏移
	add	bx, dx		; BX= FAT项在扇区内的偏移
	mov	ax, [es:bx]	; AX= FAT项值
	cmp	byte [bOdd], 1	; 是否为奇数项？
	jnz	LABEL_EVEN_2
	shr	ax, 4			; 奇数：右移4位
LABEL_EVEN_2:		; 偶数09  
	and	ax, 0FFFh	; 取低12位
LABEL_GET_FAT_ENRY_OK:
	pop	bx
	pop	es
	ret
