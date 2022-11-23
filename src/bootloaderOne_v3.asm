SECTION bootloadOne align=16 vstart=0x7c00

start:
    mov ax, 0
    mov ss, ax
    mov sp, ax                  ;设置栈段和栈顶指针为0，也就是说如果栈段一直为0，栈只能在FFFF~0f范围

    mov ax, [cs:phyBase]        ;phyBase是读取数据后存放数据的内存基地址，把它存储到es中
    mov dx, [cs:phyBase + 0x02]
    mov bx, 16
    div bx
    mov es, ax
    mov ds, ax
    xor ax, ax
    
    call main
    jmp far [0x04]
    call halt

main:
    call save_contex
    mov ax, 1
    mov bx, 1
    call readDiskReady
    mov cx, 256
    call readDiskInWord
    call realloc
    call readDiskRest
    call restore_contex
    ret

readDiskReady:              ; 设置硬盘
    call save_contex        ; ax为读取的扇区数量，bx为读取的起始扇区
    mov dx, 0x1f2   ;0x1f2 设定读取扇区数量 8位
    out dx, al

    mov ax, bx
    mov dx, 0x1f3   ;0x1f3~0x1f5 存放逻辑扇区号的0~23位 8位
    out dx, al
    xor al, al
    inc dx
    out dx, al
    inc dx
    out dx, al

    mov al, 0xe0
    mov dx, 0x1f6   ;0x1f6 低4位用于存放逻辑扇区号的24～27位， 第5位用于指示硬盘号(0主盘/1从盘), 高3位设111表LBA模式
    out dx, al

    mov al, 0x20
    mov dx, 0x1f7   ;0x1f7 第7位为1表磁盘忙碌(不能读取数据), 此位为1并且第3位为1表磁盘空闲(可以读取数据)
    out dx, al
    .wait:
        in al, dx
        and al,0x88
        cmp al,0x08
        jnz .wait
    call restore_contex
    ret

readDiskInWord:         ; 读取硬盘数据
    call save_contex    ; cx设定要读取的字节数，不过要除以2，因为每次读取两个字节
    mov dx, 0x1f0       ; 0x1f0 读硬盘端口 16位
    xor ax, ax
    xor bx, bx
    .loop:
        in ax, dx
        mov [es:bx], ax
        add bx, 2
        loop .loop
    call restore_contex
    ret

calc_segment_base:                     ;计算16位段地址
                                        ;输入：DX:AX=32位物理地址
                                        ;返回：AX=16位段基地址 
        call save_contex           
        add ax,[cs:phyBase]
        adc dx,[cs:phyBase+0x02]
        shr ax,4
        ror dx,4
        and dx,0xf000
        or ax,dx
        mov [bx], ax
        call restore_contex
         ret

realloc:
    call save_contex
    mov bx, 6
    mov ax, [bx]
    mov dx, [bx + 2]
    call calc_segment_base

    mov cx, [10]
    mov bx, 12
    .loop:
        mov ax, [bx]
        mov dx, [bx + 2]
        call calc_segment_base
        add bx, 4
        loop .loop

    mov bx, 0xfe00
    mov ax, [0]
    add ax, 511
    jc .@1
    jmp .@2
    .@1:
        mov dx, [2]
        inc dx
        mov [2], dx
    .@2:
        mov [0], ax
    call restore_contex
    ret

readDiskRest:
    call save_contex
    mov ax, [es:0]
    mov dx, [es:2]
    mov bx, 512
    div bx
    cmp ax, 1
    je .end

    dec ax
    mov cx, ax
    mov bx, 2
    call readDiskReady

    mov cx, 256
    .loop:
        mov ax, 0x200
        shr ax, 4
        mov bx, es
        add ax, bx
        mov es, ax
        call readDiskInWord
    loop .loop
    .end:
        call restore_contex
    ret

 save_contex:
     pop word [cs:stackBuffer]
     push ax
     push bx
     push cx
     push dx
     push si
     push di
     push ds
     push es
     push word [cs:stackBuffer]
     ret
 restore_contex:
     pop word [cs:stackBuffer]
     pop es
     pop ds
     pop di
     pop si
     pop dx
     pop cx
     pop bx
     pop ax
     push word [cs:stackBuffer]
     ret

halt:
    jmp $

    messageLegality db 'legal!'
    phyBase dd 0x10000
    stackBuffer dw 0
    jump_far dw 0,0

    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
