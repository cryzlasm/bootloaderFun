org 0x8000 
bits 16
mov si, msg
call changeColumn

main:
.mainLoop:
    call getKey
    and ax, 0xff
    cmp ax, 0x31
    jz .mainEnd
    call printByteValue

jmp .mainLoop
.mainEnd:


call printNullTerminatedString

jmp $   ; this freezes the system, best for testing
hlt		;this makes a real system halt
ret     ;this makes qemu halt, to ensure everything works we add both

printCharacter:
    push bx
    push ax
	;before calling this function al must be set to the character to print
	mov bh, 0x00 ;page to write to, page 0 is displayed by default
	mov bl, 0x00 ;color attribute, doesn't matter for now
	mov ah, 0x0E 
	int 0x10 ; int 0x10, 0x0E = print character in al
    pop ax
    pop bx
	ret	

printNullTerminatedString:
	pusha ;save all registers to be able to call this from where every we want
	.loop:
		lodsb ;loads byte from si into al and increases si
		test al, al ;test if al is 0 which would mean the string reached it's end
		jz .end
		call printCharacter ;print character in al
	jmp .loop ;print next character
	.end:
	popa ;restore registers to original state
	ret

changeColumn:
    pusha
    mov bh, 0x00
    mov dl, 0x10
    mov dh, 0x10
    mov ah, 0x02
    int 0x10
    popa
    ret

getKey:
    xor ah, ah
    int 0x16
    ret

printByteValue:
    push ax
    push bx

    mov bx, ax ; save byte to convert into bx

    mov al, 0x30
    call printCharacter ; print '0'

    mov al, 0x78
    call printCharacter ; print 'x'

    mov ax, bx
    shr ax, 4
    and ax,0x0f
    call hexToAscii
    call printCharacter ; print high nibble

    mov ax, bx
    and ax, 0xf
    call hexToAscii
    call printCharacter ; print low nibble

    pop bx
    pop ax
    ret

hexToAscii:
    push si

    mov si, table
    add si, ax 
    lodsb

    pop si
    ret
    
msg db "Hello Chan!", 0x00
table db "0123456789ABCDEF", 0x00
times 512-($-$$) db 0 ;kernel must have size multiple of 512 so let's pad it to the correct size
