; 主程序
; ---------------------------------------------------------------
  org 100h                        ; 程序加载到100h，可用于生成COM
[section .text]                   ; 代码段在此
; 初始化段寄存器
  mov ax,cs
  mov     ds,ax           ; DS = CS (= 4000h)
  mov     es,ax           ; ES = CS (= 4000h)
  mov ss,ax               ; SS = CS (= 4000h)
  mov sp,100h             ; 堆栈基址
  mov     ax,0B800h       ; 文本窗口显存起始地址
  mov     gs,ax           ; GS = B800h
; 初始化PCB表中的FLAGS寄存器值
  sti
  mov [kSP],sp
  mov sp,PCB1+flag_off+2
  pushf
  mov sp,[kSP]
  mov ax,[PCB1+flag_off]
  mov [PCB2+flag_off],ax
  mov [PCB3+flag_off],ax

; 设置时钟中断向量（08h），初始化段寄存器
  xor ax,ax                               ; AX = 0
  mov es,ax                       ; ES = 0
  mov word[es:20h],Timer; 设置时钟中断向量的偏移地址
  mov ax,cs
  mov [es:22h],ax         ; 设置时钟中断向量的段地址=CS
 
  call SetTimer                   ; 调用设置计数器函数

  call DispStr                    ; 显示字符串“Kernel begine...”

  jmp 6000h:100h          ; 跳转到应用程序A
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; 设置计时器函数
SetTimer:
  mov al,34h                      ; 设控制字值
  out 43h,al                              ; 写控制字到控制字寄存器
  mov ax,1193182/100      ; 每秒100次中断（10ms一次）
  out 40h,al                              ; 写计数器0的低字节
  mov al,ah                               ; AL=AH
  out 40h,al                              ; 写计数器0的高字节
  ret
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; 时钟中断处理程序
Timer: ; 使用当前进程的栈
  ; 将当前进程的寄存器值压入当前进程的栈中
  pusha
  push ds
  push es
  push fs
  push gs

  ; 计时器延时delay次
  mov ax,cs                       ; 为访问内核程序中的数据，须让
  mov ds,ax                       ; DS=CS
  dec word [count]                ; 递减计数变量
  jnz end                         ; >0：跳转到end处
  mov word [count],delay  ; =0：重置计数变量=初值delay

  ; 发送中断处理结束消息给中断控制器
  mov al,20h                      ; AL = EOI
  out 20h,al                              ; 发送EOI到主8529A
  out 0A0h,al                     ; 发送EOI到从8529A
 
  ; 调用进程调度函数
  call schedule

end: ; 中断处理善后
  ; 发送中断处理结束消息给中断控制器
  mov al,20h                      ; AL = EOI
  out 20h,al                              ; 发送EOI到主8529A
  out 0A0h,al                     ; 发送EOI到从8529A
 
  ; 恢复保存的当前进程的寄存器值
  pop gs
  pop fs
  pop es
  pop ds
  popa
  iret                                    ; 从中断处理返回
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; 进程调度函数
schedule: ; 使用当前进程的栈
  ; 复制当前进程栈中的寄存器数据到对应进程表的PCB中
  mov ax,ss
  mov ds,ax       ; DS = 当前进程栈底SS
  mov si,sp               ; SI = 当前进程栈顶SP
  add si,2                ; SP += 2 跳过Timer调用schedule的一个字
  mov ax,cs
  mov es,ax       ; ES = CS (= 4000h)
  mov di,p_proc_ready
  mov di,[es:di] ; DI = 当前PCB起始地址
  mov cx,15       ; 要复制的字数
  cld             ; 设置SI和DI递增
  rep movsw       ; 重复复制字：DS:SI => ES:DI，SI+=2、DI+=2、CX--，直到CX=0
 
  ; 设置DS=DS内核程序段值（=4000h）
  mov ax,cs
  mov ds,ax       ; DS = CS (= 4000h)
 
  mov [di],ss ; 保存当前进程的SS到PCB中
 
  ; 修改SP的值
  mov di,[p_proc_ready]   ; DI = 当前PCB起始地址
  add di,SP_off                   ; DI = PCB中的SP处
  add word [di],6                 ; SP += 6，去掉中断时入栈的3个字
 
  ; 计算下一个PCB地址，变量p_proc_ready含当前进程PCB起始地址
  add word [p_proc_ready],PCB_Size        ; p_proc_ready = 下一进程PCB的起始地址
  cmp word [p_proc_ready],MaxAddr ; 比较p_proc_ready与进程表上限值
  jl Less                                                 ; < 上限值：跳转到Less处
  mov word [p_proc_ready],PCB1    ; >= 上限值：p_proc_ready = PCB1
  Less:
  call restart                                    ; 跳转到下一个应用程序
  ret
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; 启动下一进程函数
restart: ; 先切换到PCB栈，再切换到下一进程的栈
  ; 设置SS和SP使其指向PCBi
  mov ax,cs              
  mov ds,ax                       ; DS = CS (= 4000h)
  mov ss,ax                       ; SS = CS (= 4000h)
  mov sp,[p_proc_ready]   ; SP = PCBi
  ; 已经切换到下一进程所对应的PCB栈
 
  ; 从PCB（栈）中恢复寄存器值
  pop gs
  pop fs
  pop es
  add sp,2                ; 跳过DS
  popa
  add sp,4                ; 跳过IP和CS
  popf
  pop ss          ; 开始切换到下一进程的栈

  ; 重新恢复下一进程的SP
  mov si,[p_proc_ready]   ; SI = [p_proc_ready] = PCB起始地址
  add si,SP_off                   ; SI = PCB的SP地址
  mov sp,[si]                     ; SP = 下一进程的SP值
  ; 已经切换到下一进程的栈
 
  ; 将IP和CS压入下一进程栈，供切换进程时使用
  add si,IP_off                   ; SI += 10 (=24)，指向PCB中的IP处
  push dword [si]         ; IP和CS一起入栈
 
  ; 将SI和DS压入下一进程栈，供切换进程前恢复
  mov si,[p_proc_ready]   ; SI = [p_proc_ready] = PCB起始地址
  add si,DS_off                   ; SI += 6，指向PCB中的DS处
  push word [si]                  ; 保存DS
  add si,SI_off                   ; SI += 4 (=10)，指向PCB中的SI处
  push word [si]                  ; 保存SI
 
  ; 恢复SI和DS
  pop si
  pop ds
 
  ; 切换到下一进程
  retf ; 利用栈中的IP和CS进行远程返回
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; 显示内核开始字符串函数
DispStr:
  mov ax,ds
  mov es,ax               ; ES = DS
  mov     bp,MainStr      ; BP=当前串的偏移地址
  mov     cx,18           ; CX = 串长（=18）
  mov     ax,1301h                ; AH = 13h（功能号）、AL = 01h（光标置于串尾）
  mov     bx,000Fh                ; 页号为0(BH = 0) 黑底白字(BL = 0Fh)
  mov dh,7
  mov     dl,0                    ; 行号=0、列号=0
  int     10h                     ; 显示中断
  ret
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; 数据区
[SECTION .data]
  delay equ 400                   ; 计时器延迟计数(=4秒)
  count dw delay          ; 计时器计数变量，初值=delay
  kSP dw 100h                     ; kernel当前SP
  PCB_Size equ 42         ; PCB字节数
  p_proc_ready dw PCB1    ;指向当前PCB起始地址的指针，初始化为PCB1
  FS_off equ 2                    ; FS在PCB中的偏移
  DS_off equ 6                    ; DS在PCB表的偏移
  SI_off equ 10-FS_off    ; =8，SI在PCB中的相对偏移
  SP_off equ 14                   ; SP在PCB中的偏移
  IP_off equ 24-SP_off    ; =10，IP在PCB中的相对偏移
  flag_off equ 28         ; 标志寄存器在PCB中的偏移
  ProcNo equ 3                    ; 进程总数
  MaxAddr equ PCB_Size*ProcNo+PCB1 ; PCB表的上界
  MainStr db 'Kernel begine...'   ,0Dh,0Ah ; 内核启动时显示的字符串+回车和换行
 
; 进程表
PCB1: ; 进程A的PCB
  dw 0B800h;GS \  
  dw 6000h ; FS | 部分段寄存器，用PUSH指令一个个压入栈
  dw 6000h ; ES |
  dw 6000h ; DS /
  dw 0     ; DI \
  dw 0     ; SI | 指针寄存器 \
  dw 0     ; BP |            |
  dw 100h-4; SP /            | 通用寄存器，用PUSHA指令一起压入栈
  dw 0     ; BX \           |
  dw 0     ; DX | 主寄存器  /
  dw 0     ; CX |
  dw 0     ; AX /
  dw 100h  ; IP 指令指针寄存器 \
  dw 6000h ; CS 代码段寄存器    | 中断时由CPU压入栈
  dw 0     ; Flags 标志寄存器  /
  dw 6000h ; SS 堆栈段寄存器，手工赋值
  dw 1     ; ID 进程ID
  db 'ProcessA' ; Name 进程名（8个字符）
PCB2: ; 进程B的PCB
  dw 0B800h;GS \
  dw 7000h ; FS | 部分段寄存器，用PUSH指令一个个压入栈
  dw 7000h ; ES |
  dw 7000h ; DS /
  dw 0     ; DI \
  dw 0     ; SI | 指针寄存器 \
  dw 0     ; BP |            |
  dw 100h-4; SP /            | 通用寄存器，用PUSHA指令一起压入栈
  dw 0     ; BX \           |
  dw 0     ; DX |主寄存器   /
  dw 0     ; CX |
  dw 0     ; AX /
  dw 100h  ; IP 指令指针寄存器 \
  dw 7000h ; CS 代码段寄存器   | 中断时由CPU压入栈
  dw 0     ; Flags 标志寄存器  /
  dw 7000h ; SS 堆栈段寄存器，手工赋值
  dw 2     ; ID 进程ID
  db 'ProcessB' ; Name 进程名（8个字符）
PCB3: ; 进程C的PCB
  dw 0B800h;GS \
  dw 8000h ; FS | 部分段寄存器，用PUSH指令一个个压入栈
  dw 8000h ; ES |
  dw 8000h ; DS /
  dw 0             ; DI \
  dw 0             ; SI | 指针寄存器 \
  dw 0             ; BP |            |
  dw 100h-4; SP /                  | 通用寄存器，用PUSHA指令一起压入栈
  dw 0     ; BX \                  |
  dw 0     ; DX | 主寄存器      /
  dw 0     ; CX |
  dw 0     ; AX /
  dw 100h  ; IP 指令指针寄存器 \
  dw 8000h ; CS 代码段寄存器   | 中断时由CPU压入栈
  dw 0     ; Flags 标志寄存器  /
  dw 8000h ; SS 堆栈段寄存器，手工赋值
  dw 3     ; ID 进程ID
  db 'ProcessC' ; Name 进程名（8个字符）
; ---------------------------------------------------------------

