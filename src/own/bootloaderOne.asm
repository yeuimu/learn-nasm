;       FFFFF   --------------------
;               - ROM BIOS         -
;       A0000   --------------------    9FFFF
;               - available spaces -
;       10000   --------------------    0FFFF
;               - bootloaderOne    -
;       0c700   --------------------    0c6FF
;               - reserve          -
;               --------------------    00000



SECTION bootloadOne align=16 vstart=0x7c00
        jmp start

        message db 0, 0, 0, 0, 0, 0

        ;Set up stack segment regoster and stack pointer register
start:  mov ax, 0
        mov ss, ax
        mov sp, ax

        ;Read second sector of disk
        ;Read one sector
        mov al, 1
        mov dx, 0x1f2
        out dx, al

        ;Read second sector
        mov al, 2
        inc dx
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

        ;Enable reading disk
        mov al, 0x20
        mov dx, 0x1f7
        out dx, al
        call .wait

        ;读取第二扇区的头
        mov cx, 3
        mov dx, 0x1f0
        mov ax, message
        mov es, ax
        xor ax, ax
        mov bx, 0

.readHeader:
        in ax, dx
        mov [es:bx], ax
        add bx, 2
        loop .readHeader

        jmp .end

.wait:
        in al, dx
        and al,0x88
        cmp al,0x08
        jnz .wait 
        ret

.end:
        mov ax, 0xb800
        mov es, ax
        mov ax, message
        mov ds, ax
        mov cx, 6
        mov bx, 0
        mov si, 0
        mov di, 0

.loop:
        mov al, [si]
        mov [es:di], al
        inc si
        inc di
        mov byte [es:di], 0x07
        inc di
        loop .loop

        jmp $

        times 510 - ($ - $$) db 0
        db 0x55, 0xaa
