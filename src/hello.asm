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

halt:
        jmp halt

times 510 - ($ -$$) db 0
db 0x55, 0xaa

