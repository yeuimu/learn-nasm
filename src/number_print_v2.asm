org 0x7c00

jmp start

variable: 
        number: db 0, 0, 0, 0
start:
        ;设置ds
        mov ax, number
        mov ds, ax
        ;设置被除数
        mov ax, 1111
        xor dx, dx
        mov si, 10
	mov di, 0
	mov cx, 4

gain_digit:
        div si
        mov [di], dl
	inc di
        xor dx, dx
	loop gain_digit

	xor si, si
	xor di, di
        mov ax, 0xb800
        mov es, ax
	mov si, 3
	mov di, 0
show:
	mov ah, 0x40
	mov byte al, [si]
	add al, 0x30
	mov [es:di], ax
	add di, 2
	dec si
	jns show
	
halt:
        jmp halt

times 510 - ($ - $$) db 0
db 0x55, 0xaa
