SECTION header align=16 vstart=0

    ;Length of the program
    lengthProgram dd endProgram

    ;Location table
    segmentTXT dd section.txt.start
    segmentDATE dd section.date.start

    ;Start address after the while code located the specialy location
    offerStartProgram dw start
    segmentStartProgram dd section.txt.start

    ;Magic number is tested whether the header is legal
    magicNumber dw 0xaa55

SECTION txt align=16 vstart=0

start:
    xor ax, ax
    mov bx, ax
    mov cx, ax
    mov dx, ax
    mov si, ax
    mov di, ax

    mov ds, [es:8]

    .print:
        mov ax, 0xb800
        mov es, ax
        xor si, si
        xor di, di
        mov cx, 6

    .printLoop:
        mov ax, [ds:si]
        inc si
        mov [es:di], ax
        inc di
        mov byte [es:di], 0x07
        inc di
        loop .printLoop

    jmp $

SECTION date1 align=16 vstart=0

    resb 10240

SECTION date align=16 vstart=0
   message db 'hello!'

SECTION trail align=16

endProgram: