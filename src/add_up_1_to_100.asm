jmp near start

message db '1+2+3+...+100='

start:
        ;初始化ds和es
        mov ax, 0x07c0
        mov ds, ax

        mov ax, 0xb800
        mov es, ax

        mov ax, 0
        mov ss, ax
        mov sp, ax

        ;初始化si和di以及cx
        mov si, message
        mov di, 0
        mov cx, start - message

printMessage:
        mov al, [si]
        mov [es:di], al
        inc di
        mov byte [es:di], 0x07
        inc di
        inc si
        loop printMessage

        xor ax, ax
        mov cx, 1
oneToHhunderd:
        add ax, cx
        inc cx
        cmp cx, 100
        jle oneToHhunderd

        mov bx, 10
        xor cx, cx
gainDigit:
        inc cx
        xor dx, dx
        div bx
        or dl, 0x30
        push dx
        cmp ax, 0
        jne gainDigit

        mov bx, (start - message) * 2
        mov si, 0
printNumber:
        pop dx
        mov [es:bx+si], dl
        inc si
        mov byte [es:bx+si], 0x07
        inc si
        loop printNumber

jmp near $

times 510 - ($ - $$) db 0
dw 0xaa55
