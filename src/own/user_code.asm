SECTION header vstart=0
	;Length of program
        lengthProgram	dd endProgram
        
        ;Entry of user program
        entryCode	dw start
                        dd section.code1.start        
        
        ;Segment of reorientation
        code1Segment  dd section.code1.start
	endHeader:                
    
SECTION code1 align=16 vstart=0
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

SECTION trail align=16
endProgram:

