SECTION header align=16 vstart=0

    ;Length of the program
    lengthProgram dd endProgram

    ;Location table
    segmentTXT dd section.txt.start
    segmentDATE dd section.date.start

    ;Start address after the while code located the specialy location
    segmentStartProgram dd section.txt.start
    offerStartProgram dw start

    ;Magic number is tested whether the header is legal
    magicNumber dw 0xaa55

endHeader:

SECTION txt align=16 vstart=0

start:
    mov ax, 0xb800
    mov ds, ax

    mov byte [0], 'H'
    mov byte [1], 0x07
    mov byte [2], 'e'
    mov byte [3], 0x07
    mov byte [4], 'l'
    mov byte [5], 0x07
    mov byte [6], 'l'
    mov byte [7], 0x07
    mov byte [8], 'o'
    mov byte [9], 0x07
    mov byte [10], '!'
    mov byte [11], 0x07

    jmp $


SECTION date align=16 vstart=0

endProgram: