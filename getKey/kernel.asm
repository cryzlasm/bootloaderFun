org 0x8000 
bits 16

call initScreen ; screen initialisation, set the fixed strings on the screen


main:
.mainLoop: ; main loop, wait for a keypress and print details on screen
    call getKey ; wait and get the return value from a keypress into ax
    cmp ax, 0x0231 ; if the key is '1', leave the main loop. (Arbitrary value, no particular raison)
    jz .mainEnd
    call printWordValue ; print keycode values on screen

jmp .mainLoop
.mainEnd:


mov si, posChan ;
lodsw ; ax = [si]
call setCursorPosition ; Change cursor position

mov si, stringChan
call printNullTerminatedString

jmp $   ; this freezes the system, best for testing
hlt		; this makes a real system halt
ret     ; this makes qemu halt, to ensure everything works we add both



; #########################################
;              FUNCTIONS
; #########################################

initScreen: ; Screen initialisation. Cleanup and print permanent string
            ; Args : None
    pusha ; save all registers

    call clearScreen ; clean screen

    mov si, posBanner
    lodsw
    call setCursorPosition ; Update cursor position

    mov si, stringBanner
    call printNullTerminatedString ; print Banner

    mov si, posAhCaption
    lodsw
    call setCursorPosition ; Update cursor position

    mov si, ahCaption
    call printNullTerminatedString ; print "AH: "

    mov si, posAlCaption
    lodsw
    call setCursorPosition ; Update cursor position

    mov si, alCaption
    call printNullTerminatedString ; print "AL: "

    popa ; restore all registers
    ret

clearScreen: ; Clean screen
             ; Args : None
    pusha

    mov ax, 0x0700  ; function 07, AL=0 means scroll whole window
    mov bh, 0x07    ; character attribute = white on black
    mov cx, 0x0000  ; row = 0, col = 0
    mov dx, 0x184f  ; row = 24 (0x18), col = 79 (0x4f)
    int 0x10        ; call BIOS video interrupt

    popa
    ret


printCharacter: ; Print a char at current cursor location
                ; Args : 
                ; AL : char ascii value
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

printNullTerminatedString: ; Print a null terminated string
                           ; Args :
                           ; SI : string address
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

setCursorPosition: ; Change cursor position
                   ; Args :
                   ; AH : line number
                   ; AL : column number
    pusha
    mov dx, ax
    mov bh, 0x00
    mov ah, 0x02
    int 0x10
    popa
    ret

getKey: ; Return a keystroke value into ax
    xor ah, ah
    int 0x16
    ret

printWordValue: ; Print word value on screen
    pusha
    mov bx, ax ; save ax into bx
    shr ax, 8 ; get AH into AL, AH = 0
    call printHighByte ; print original AH value

    mov ax, bx
    and ax, 0xFF ; null the AH part
    call printLowByte ; print original AL value

    popa
    ret


printHighByte: ; Print the byte value in front of the 'AH' label.
               ; Should be merged with printLowByte
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

printLowByte: ; Print the byte value in front of the 'AL' label
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

hexToAscii: ; convert an hex value between 0 and f into its ascii value
    push si

    mov si, hexChar ; hexChar is an ascii table, the hex value is an offset into this table
    add si, ax 
    lodsb

    pop si
    ret
    

posBanner dw 0x0013 ; line : 0; column : 0x13
posChan dw 0x1010 ; L: 0x10, C: 0x10

posAhCaption dw 0x0400; L: 0x04, C: 0x00
posAhValue   dw 0x0404; L: 0x04, C: 0x04

posAlCaption dw 0x0500; L: 0x05, C: 0x00
posAlValue   dw 0x0504; L: 0x05, C: 0x04

stringChan db "Hello Chan!", 0x00
stringBanner db "Printing your last keystroke value", 0x00

ahCaption db "AH: ", 0x00
alCaption db "AL: ", 0x00

hexChar db "0123456789ABCDEF", 0x00


times 512-($-$$) db 0 ;kernel must have size multiple of 512 so let's pad it to the correct size
