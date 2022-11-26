    sizeHeader equ 20
    startDiskSector equ 1

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

    mov ax, 1
    push ax
    push ax
    call readDisk
    pop ax
    pop ax

    call readDiskInWord

    call realloc

    mov ax, [es:0]
    mov dx, [es:2]
    mov bx, 512
    div bx
    
    cmp ax, 1
    je jmpfar

    dec ax
    mov cx, ax
    push 2
    push ax
    call readDisk
    pop ax
    pop ax

    push es
    .read_start:
        mov ax, 0x200
        shr ax, 4
        mov bx, es
        add ax, bx
        mov es, ax
        call readDiskInWord
    loop .read_start
    pop es

jmpfar:
    jmp far [12]

    call halt

readDisk:
    push bp
    mov bp, sp
    call save_contex

    mov ax, [bp + 4]
    ; mov al, 1
    mov dx, 0x1f2   ;0x1f2 设定读取扇区数量 8位
    out dx, al

    mov ax, [bp + 6]
    ; mov al, 1
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
    mov sp, bp
    pop bp
    ret

readDiskInWord:
    call save_contex
    mov cx, 256     ; 读取512字节, 每次读取2个字节
    mov dx, 0x1f0   ; 0x1f0 读硬盘端口 16位
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
        push bp
        mov bp, sp
        call save_contex           
        
        mov ax, [bp + 4]
        mov dx, [bp + 6]
        add ax,[cs:phyBase]
        adc dx,[cs:phyBase+0x02]
        shr ax,4
        ror dx,4
        and dx,0xf000
        or ax,dx

        mov [bx], ax
        
        call restore_contex
        mov sp, bp
        pop bp
         
         ret

realloc:
    call save_contex

    mov cx, 2
    mov bx, 4

    .reallocLoop:
        mov ax, [bx]
        mov dx, [bx + 2]
        push dx
        push ax
        call calc_segment_base
        pop ax
        pop dx
        add bx, 4
        loop .reallocLoop

    mov bx, 14
    mov ax, [bx]
    mov dx, [bx + 2]
    push dx
    push ax
    call calc_segment_base
    pop ax
    pop dx

    mov bx, 512         ; 这里保证是512b对齐，所以不存在余数
    dec bx              ; 那么如何字节对齐呢？二进制有个规律，保证低位几个零那就是2的几次方字节对齐
    not bx              ; 比如保证2字节对齐，2^1=2，那么保证最后一位为0则可以2字节对齐
    mov ax, [0]         ; 再比如保证8字节对齐，2^3=8，那么保证最后三位为0则可以8字节对齐
    add ax, 512 - 1     ; 这里就是 2^9=512 (log(2)(512)) 所以保证最后九位为0则可以512字节对齐
    jc .carry
    jmp .nocarry

    .carry:
        mov dx, [2]
        add dx, 1
        jmp .continue
    .nocarry:
        mov dx, [2]
    .continue:
        and ax, bx
    mov [0], ax
    mov [2], dx

    call restore_contex
    ret

 save_contex:
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
 restore_contex:
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

halt:
    jmp $

    messageLegality db 'legal!'
    phyBase dd 0x10000
    stack_tmp dw 0
    jump_far dw 0,0


    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
