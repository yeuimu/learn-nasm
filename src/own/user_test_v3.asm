SECTION header align=16 vstart=0

    lengthProgram dd endProgram ;0

    entryProgram  dw start ;4
                  dd section.txt1.start ;6
    reallocItem   dw (endHeader - reallocTable) / 4 ;10
    reallocTable  dd section.txt1.start  ;12
                  dd section.data1.start ;16
                  dd section.stack.start ;20
    endHeader:

SECTION txt1 align=16 vstart=0

start:
    mov ds, [es:16]
    mov ss, [es:20]

    print:
    mov ax, 0xb800
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 6
    .loop:
        mov ax, [ds:si]
        inc si
        mov [es:di], ax
        inc di
        mov byte [es:di], 0x07
        inc di
        loop .loop

    jmp $

SECTION data1 align=16 vstart=0
   message db 'hello!'

SECTION stack align=16 vstart=0
    resb 256

SECTION trail align=16

endProgram: