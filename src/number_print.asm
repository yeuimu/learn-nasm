org 0x7c0

mov ax, 1234
mov dx, 0
mov bx, 10
mov cx, number;如果没有`org 0x7c0`，这里就要加上偏移量0x7c0
mov ds, cx

;个位
div bx
mov [0], dx
xor dx, dx

;十位
div bx
mov [1], dx
xor dx, dx

;百位
div bx
mov [2], dx
xor dx, dx

;千位
div bx
mov [3], dx
xor dx, dx

mov al, [0]
add al, 0x30
mov [0], al

mov al, [1]
add al, 0x30
mov [1], al

mov al, [2]
add al, 0x30
mov [2], al

mov al, [3]
add al, 0x30
mov [3], al

mov ax, 0xb800
mov es, ax
mov bx, 0x07

mov ax, [3]
mov [es:0], ax
mov [es:1], bx

mov ax, [2]
mov [es:2], ax
mov [es:3], bx

mov ax, [1]
mov [es:4], ax
mov [es:5], bx

mov ax, [0]
mov [es:6], ax
mov [es:7], bx

halt:
        jmp halt

number db 0x00, 0x00, 0x00, 0x00

times 510 - ($ - $$) db 0
db 0x55, 0xaa
