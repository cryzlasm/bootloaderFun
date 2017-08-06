org 0x8000 
bits 16

call initScreen

main:
.mainLoop:
    call getKey
    cmp ax, 0x0231
    jz .mainEnd
    call printByteValue

jmp .mainLoop
.mainEnd:


mov si, posChan
lodsw
call setCursorPosition

mov si, stringChan
call printNullTerminatedString

jmp $   ; this freezes the system, best for testing
hlt		;this makes a real system halt
ret     ;this makes qemu halt, to ensure everything works we add both



; #########################################
; #########################################

initScreen:
    pusha

    mov al, 0x03
    mov ah, 0x0
    int 0x10

    call clearScreen

    mov si, posBanner
    lodsw
    call setCursorPosition

    mov si, stringBanner
    call printNullTerminatedString

    mov si, posAhCaption
    lodsw
    call setCursorPosition

    mov si, ahCaption
    call printNullTerminatedString

    mov si, posAlCaption
    lodsw
    call setCursorPosition

    mov si, alCaption
    call printNullTerminatedString

    popa
    ret

clearScreen:
    pusha

    mov ax, 0x0700  ; function 07, AL=0 means scroll whole window
    mov bh, 0x07    ; character attribute = white on black
    mov cx, 0x0000  ; row = 0, col = 0
    mov dx, 0x184f  ; row = 24 (0x18), col = 79 (0x4f)
    int 0x10        ; call BIOS video interrupt

    popa
    ret


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

setCursorPosition:
    pusha
    mov dx, ax
    mov bh, 0x00
    mov ah, 0x02
    int 0x10
    popa
    ret

getKey:
    xor ah, ah
    int 0x16
    ret

printByteValue:
    pusha
    mov bx, ax
    shr ax, 8
    call printHighNibble

    mov ax, bx
    and ax, 0xFF
    call printLowNibble

    popa
    ret


printHighNibble:
    push ax
    push bx

    mov bx, ax ; save byte to convert into bx

    mov si, posAhValue
    lodsw
    call setCursorPosition

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

printLowNibble:
    push ax
    push bx

    mov bx, ax ; save byte to convert into bx
    mov si, posAlValue
    lodsw
    call setCursorPosition

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

    mov si, hexChar 
    add si, ax 
    lodsb

    pop si
    ret
    

posBanner dw 0x0013
posChan dw 0x1010

posAhCaption dw 0x0400
posAhValue   dw 0x0404

posAlCaption dw 0x0500
posAlValue   dw 0x0504

stringChan db "Hello Chan!", 0x00
stringBanner db "Printing your last keystroke value", 0x00

ahCaption db "AH: ", 0x00
alCaption db "AL: ", 0x00

hexChar db "0123456789ABCDEF", 0x00


times 512-($-$$) db 0 ;kernel must have size multiple of 512 so let's pad it to the correct size
