;       FFFFF   --------------------
;               - ROM BIOS         -
;       A0000   --------------------    9FFFF
;               - available spaces -
;       10000   --------------------    0FFFF
;               - bootloaderOne    -
;       0c700   --------------------    0c6FF
;               - reserve          -
;               --------------------    00000

    sizeHeader equ 20
    startDiskSector equ 1

SECTION bootloadOne align=16 vstart=0x7c00

    jmp main

main:  

    init:
        ;设置栈段和栈顶指针为0，也就是说如果栈段一直为0，栈只能在FFFF~0f范围
        mov ax, 0
        mov ss, ax
        mov sp, ax

        ;phyBase是读取数据后存放数据的内存基地址，把它存储到es中
        mov ax, [cs:phyBase]
        mov dx, [cs:phyBase + 0x02]
        mov bx, 16
        div bx
        mov es, ax
        mov ds, ax

    ; 读取扇区头
    call .readDiskHeader

    ; ; 开始正式读取这个扇区
    call .readDiskAll

    ; 修正用户程序的重定位表
    call .realloc

    ; 开始长跳转
    jmp far [12]

    call .halt

; .readDisk:
;     push bp
;     mov bp, sp
;     mov ax, [bp + 4]
;     mov al, 1
;     mov dx, 0x1f2   ;0x1f2 设定读取扇区数量
;     out dx, al

;     mov ax, [bp + 6]
;     mov al, 0xe0
;     mov dx, 0x1f6   ;0x1f6 低4位用于存放逻辑扇区号的24～27位， 第5位用于指示硬盘号(0主盘/1从盘), 高3位设111表LBA模式
;     out dx, al

;     mov ax, [bp + 8]   
;     mov al, 1
;     mov dx, 0x1f3   ;0x1f3~0x1f5 存放逻辑扇区号的0~23位
;     out dx, al
;     xor al, al
;     inc dx
;     out dx, al
;     inc dx
;     out dx, al

;     mov al, 0x20
;     mov dx, 0x1f7   ;0x1f7 第7位为1表磁盘忙碌(不能读取数据), 此位为1并且第3位为1表磁盘空闲(可以读取数据)
;     out dx, al
;     .readyWaits:
;         in al, dx
;         and al,0x88
;         cmp al,0x08
;         jnz .readyWaits

;     mov cx, 256     ; 读取512字节, 每次读取2个字节
;     mov dx, 0x1f0   ; 0x1f0 读硬盘端口
;     xor ax, ax
;     xor bx, bx
;     .readLoop:
;             in ax, dx
;             mov [es:bx], ax
;             add bx, 2
;             loop .readLoop

;     mov sp, bp
;     pop bp
;     ret

;函数：readDiskHeader
;功能：读取磁盘数据的头，并检验数据合法性（头最后两个字节是否为0x55aa）
;参数：通过宏来指定，sizeHeader指定头的大小，startDiskSector指定数据所在硬盘的起始扇区，目前仅支持2~255扇区的范围
.readDiskHeader:
    ;使用栈传递参数
    push bp
    mov bp, sp

    call .save_contex

    ;设定读取扇区数量，这里读取扇区头，只需要读取一个扇区
    mov ax, 1
    push ax
    call .readSectorCount
    pop ax

    ;指定从哪个扇区开始读取
    mov ax, startDiskSector
    push ax
    call .readStartWhichSector
    pop ax

    ;等待硬盘
    call .readWaitDisk

    ;使用栈传递参数，指定要读取的字节，这里读取的是头部20个字节，也就是所谓的扇区头
    mov ax, 512
    push ax
    ; 0x7c3f
    call .readDiskInWord
    pop ax

    ;打印头部是否合法
    call .checkLegality

    call .restore_contex

    mov sp, bp
    pop bp
    ret

; 使用栈传递参数
; 函数：readSectorCount
; 功能：设定读取磁盘几个扇区
; 参数：只有一个参数，这个参数就是要读取的扇区数量，注意这个数不能超过255，因为`out`指令只能使用8位寄存器
.readSectorCount:
    push bp
    mov bp, sp

    call .save_contex

    ; [bp + 4] 即为第一个参数，为什么是加四呢，因为上面bp压入了一次，如果不压如就是加二
    mov ax, [bp + 4]
    ;Read second sector of disk
    ;Read one sector
    ; mov al, ah
    mov dx, 0x1f2
    out dx, al

    ; xor ah, ah
    call .restore_contex

    mov sp, bp
    pop bp
    ret

; 使用栈传递参数
; 函数：
; 功能：设定要读取的数据所在硬盘的起始扇区
; 参数：目前只能限定在1~255的扇区范围
.readStartWhichSector:
    push bp
    mov bp, sp

    call .save_contex

    ;Read second sector
    mov ax, [bp + 4]
    mov dx, 0x1f3
    out dx, al
    xor al, al
    inc dx
    out dx, al
    inc dx
    out dx, al

    ;Set LBA mod
    mov al, 0xe0
    mov dx, 0x1f6
    out dx, al

    call .restore_contex

    mov sp, bp
    pop bp
    ret

; 函数：readWaitDisk
; 功能：使能硬盘，并等待硬盘准备好被读取数据，准备好后就可以读取硬盘了
; 参数：无
.readWaitDisk:
        call .save_contex

        ;Enable reading disk
        mov al, 0x20
        mov dx, 0x1f7
        out dx, al
        .readWaitDiskWaits:
            in al, dx
            and al,0x88
            cmp al,0x08
            jnz .readWaitDiskWaits

        call .restore_contex
        ret

.readDiskInWord:            ; 函数：readDiskInWord
    call .save_contex       ; 功能：读取硬盘数据
    mov cx, 256             ; 参数：无参数，一次只能读取512个字节，读取的地址存储在es中
    mov dx, 0x1f0
    xor ax, ax
    xor bx, bx
    .readDiskInWordLoop:
            in ax, dx
            mov [es:bx], ax
            add bx, 2
            loop .readDiskInWordLoop
    call .restore_contex
    ret

.checkLegality:             ; 函数：checkLegality
    call .save_contex       ; 功能：检验位于硬盘要读取的数据的合法性
    mov di, 18              ; 参数：无
    mov ax, [es:di]         ; 注意：硬盘上的数据读取到了phyBase以这个宏为基地址的内存地址上，此地址开头存储到了es寄存器里
    cmp ax, 0xaa55
    je .printLegality

    call .restore_contex
    ret

    .printLegality:
        mov ax, 0xb800
        mov es, ax
        xor si, si
        xor di, di
        mov bx, messageLegality
        mov cx, 6

        .printLegalityLoop:
            mov ax, [cs:bx + si]
            inc si
            mov [es:di], ax
            inc di
            mov byte [es:di], 0x07
            inc di
            loop .printLegalityLoop
    call .restore_contex
    ret

.readDiskAll:
    push bp
    mov bp, sp
    call .save_contex

    mov bx, 512         ; 这里保证是512b对齐，所以不存在余数
    dec bx              ; 那么如何字节对齐呢？二进制有个规律，保证低位几个零那就是2的几次方字节对齐
    not bx              ; 比如保证2字节对齐，2^1=2，那么保证最后一位为0则可以2字节对齐
    mov ax, [es:0]      ; 再比如保证8字节对齐，2^3=8，那么保证最后三位为0则可以8字节对齐
    add ax, 512 - 1     ; 这里就是 2^9=512 (log(2)(512)) 所以保证最后九位为0则可以512字节对齐
    jc .carry
    jmp .nocarry

    .carry:
        mov dx, [es:2]
        add dx, 1
        jmp .continue
    .nocarry:
        mov dx, [es:2]
    .continue:
        and ax, bx
    mov [es:0], ax
    mov [es:2], dx

    mov ax, [es:0]
    mov dx, [es:2]
    mov bx, 512
    div bx
    
    cmp ax, 1
    je .readDiskAllEnd
    jmp .read

    .read:
        dec ax          ;ax 为还需要读取多少个磁盘块（512字节）
        mov cx, ax
        push ax
        call .readSectorCount
        pop ax
        mov ax, startDiskSector + 1
        push ax
        call .readStartWhichSector
        pop ax
        call .readWaitDisk

    .read_start:
        mov ax, 0x200
        shr ax, 4
        mov bx, es
        add ax, bx
        mov es, ax
        call .readDiskInWord
    loop .read_start

    .readDiskAllEnd:
        call .restore_contex
        mov sp, bp
        pop bp
        ret

.calc_segment_base:                     ;计算16位段地址
                                        ;输入：DX:AX=32位物理地址
                                        ;返回：AX=16位段基地址 
        push bp
        mov bp, sp
        call .save_contex                         
         
        add ax,[cs:phyBase]
        adc dx,[cs:phyBase+0x02]
        shr ax,4
        ror dx,4
        and dx,0xf000
        or ax,dx

        mov [bx], ax
        
        call .restore_contex
        mov sp, bp
        pop bp
         
         ret

.realloc:
    call .save_contex

    mov cx, 2
    mov bx, 4

    .reallocLoop:
        mov ax, [es:bx]
        mov dx, [es:bx + 2]
        call .calc_segment_base
        add bx, 4
        loop .reallocLoop

    mov bx, 14
    mov ax, [bx]
    mov dx, [bx+2]
    call .calc_segment_base

    call .restore_contex
    ret

.save_contex:
    pop word [cs:stack_tmp]
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    push word [cs:stack_tmp]
    ret

.restore_contex:
    pop word [cs:stack_tmp]
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    push word [cs:stack_tmp]
    ret

.halt:
    jmp $

    messageLegality db 'legal!'
    phyBase dd 0x10000
    stack_tmp dw 0
    jump_far dw 0,0


    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
