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

    startDiskSector equ 2

SECTION bootloadOne align=16 vstart=0x7c00

        jmp main

main:  

    init:
        ;Set up stack segment regoster and stack pointer register
        mov ax, 0
        mov ss, ax
        mov sp, ax

        ;The ES segment register get location address of app
        mov ax, [cs:phyBase]
        mov dx, [cs:phyBase + 0x02]
        mov bx, 16
        div bx
        mov es, ax

    call .readDiskHeader

    call .halt

.init:
    

.readDiskHeader:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ;读取扇区头只需要读取一个扇区
    mov ah, 1
    call .readSectorCount

    ;指定从哪个扇区开始读取
    mov ah, startDiskSector
    call .readStartWhichSector

    ;等待硬盘
    call .readWaitDisk

    ;使用 si 寄存器来指定要读取的字节，这里读取的是头部20个字节
    mov si, sizeHeader
    call .readDiskInWord

    ;打印头部是否合法
    call .checkLegality

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


;使用 ah 传递要读取的扇区数量
.readSectorCount:
        push dx

        ;Read second sector of disk
        ;Read one sector
        mov al, ah
        mov dx, 0x1f2
        out dx, al

        xor ah, ah
        pop dx
        ret

;使用 ah 传递起始扇区
.readStartWhichSector:
        push dx

        ;Read second sector
        mov al, ah
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
        
        xor ah, ah
        pop dx
        ret

.readWaitDisk:
        push dx

        ;Enable reading disk
        mov al, 0x20
        mov dx, 0x1f7
        out dx, al
        .readWaitDiskWaits:
            in al, dx
            and al,0x88
            cmp al,0x08
            jnz .readWaitDiskWaits

        pop dx
        ret

;使用 si 寄存器传递要读取的字节数
.readDiskInWord:
        push ax
        push bx
        push dx
        push cx

        ;读取第二扇区的头
        mov cx, si  ;这里指定头的字节数
        mov dx, 0x1f0
        xor ax, ax
        xor bx, bx

        .readDiskInWordLoop:
                in ax, dx
                mov [es:bx], ax
                add bx, 2
                loop .readDiskInWordLoop

        xor si, si
        pop cx
        pop dx
        pop bx
        pop ax
        ret

.checkLegality:
    push ax
    push bx
    push cx
    push es
    push si
    push di
    
    mov di, 18
    mov ax, [es:di]
    cmp ax, 0xaa55
    je .printLegality

    pop di
    pop si
    pop es
    pop cx
    pop bx
    pop ax
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

    pop di
    pop si
    pop es
    pop cx
    pop bx
    pop ax
    ret

.halt:
    jmp $

    messageLegality db 'legal!'

    phyBase dd 0x10000


    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
