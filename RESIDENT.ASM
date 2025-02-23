.model tiny
.code
org 100h

start:

call Main

reg_len = 10 - 1
ax_reg: db 'AX = 0000$'
bx_reg: db 'BX = 0000$'
cx_reg: db 'CX = 0000$'
dx_reg: db 'DX = 0000$'
di_reg: db 'DI = 0000$'
cs_reg: db 'CS = 0000$'
ip_reg: db 'IP = 0000$'
si_reg: db 'SI = 0000$'


RegToStr proc
	
	push ax bx cx dx	
	mov cx, 4	
	push di

	convert_loop:
		dec di
		xor dx, dx
		mov dx, ax
		and dx, 000fh
		cmp dl, 9d
		jbe is_digit
		add dl, 7
	
		is_digit:
		add dl, '0'
		mov [di], dl
		shr ax, 4
		loop convert_loop

	pop si
	sub si, reg_len
	push cs
	pop ds
	mov di, bx
	mov ah, 00101110b
	loooper:
		lodsb
		cmp al, '$'
		je loooper_end
		stosw
		jmp loooper

	loooper_end:
	pop dx cx bx ax
	ret
	endp
;-------------------------------------------------------------
; Draws a frame of size (x * y) in FrameStyle(1, 2, or 3)
; Entry: x in dh, y in dl, color style in cx
; Exit: None
; Destr: AX, DX, CH, DI, SI
;-------------------------------------------------------------

DrawRect proc
	
	push cx				; Pushing ColorStyle to stack

	xor ax, ax		 	;Cleaning register
	mov di, 17 * 80 * 2 + 64	;Start video memory bias



	xor cx, cx			;Cleaning registers	
	xor ax, ax		


	pop ax
	;mov ah, 00001100b		;Color of Rectangle (can be modified)
	sub dh, 1		 
	sub dl, 1		
	mov ch, 1		

	push di			    
	mov si, offset FrameStyle1 	;Setting the first three
	call DrawLine		     	;characters of FrameStyle
	pop di			     	;and drawing the first line

	add di, 2 * 80		   	;Moving di to the next line

					;Cycle where mid lines of rectangle are drawn	

	rect_cycle:				;|
						;|
		cmp dh, ch			;|
		je end_rect_cycle		;|		

		push di				;|
		push cx				;|
		mov si, offset FrameStyle1+3
		call DrawLine			;|
		;sub si, 3
		pop cx				;|
		pop di				;|
		add di, 2 * 80			;|
						;|
		inc ch 				;|
		jmp rect_cycle			;|

	end_rect_cycle:	

					;Drawing the last line
	push di
	;add si, 3				;|

	mov si, offset FrameStyle1+6
	call DrawLine				;|
	pop di					;|
						;|
	ret					;|
	endp					;|



;-------------------------------------------------------------
; Draws a line of <start symbol> <n * mid symbol> <end symbol>
; Entry: n in dl
; Exit: None
; Destr: DX, CX, AX, SI, DI, ES
;-------------------------------------------------------------

DrawLine proc

	xor cx, cx
	mov cl, dl

	lodsb
	stosw	

	lodsb	
	rep stosw

	lodsb
	stosw	

	ret
	endp


running db 0

;----------------------------
;	Main Part
;----------------------------
Main proc
	xor ax, ax
	mov es, ax
	mov bx, 09h * 4

	mov ax, es:[bx]
	mov oldbias, ax
	mov ax, es:[bx+2]
	mov oldsegm, ax

	cli
	mov es:[bx], offset Rez
	mov ax, cs
	mov es:[bx+2], ax
	sti

	mov dx, offset Main
	shl dx, 4
	inc dx
	mov ax, 3100h
	int 21h	
	ret
	endp

;----------------------------
;	Resident Part
;----------------------------

clear_screen:
	mov dh, 5d
	mov dl, 30d
	xor cx, cx
	call DrawRect
	jmp show_end

Rez proc
	push ax bx es
	mov ax, 0b800h
	mov es, ax
	mov bx, 5 * 80 * 2 + 40 * 2

	in al, 60h
	cmp al, 81h
	je clear_screen
	cmp al, 9dh
	je show_reg
	jmp show_end

	show_reg:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
 
	mov dh, 5d
	mov dl, 30d
	mov cx, 0abcdh
	
	push cs
	pop ds
	call DrawRect
	
	xor ax, ax	
	int 1ah
	mov ax, dx
	mov ch, 0ffh
	sub ch, dl

	mov bx, 2 * 80 * 18 + 68
	lea di, [ax_reg+reg_len]
	call RegToStr

	push bx
	add bx, 2 * 15
	lea di, [di_reg+reg_len]
	push ax
	mov ax, di
	call RegToStr
	pop ax
	pop bx

	add bx, 2 * 80

	lea di, [bx_reg + reg_len]
	push ax
	mov ax, bx
	call RegToStr
	pop ax

	push bx
	add bx, 2 * 15
	lea di, [si_reg+reg_len]
	push ax
	push si
	pop ax
	call RegToStr
	pop ax
	pop bx

	add bx, 2 * 80
	lea di, [cx_reg+reg_len]	
	push ax
	mov ax, cx
	call RegToStr
	pop ax

	push bx
	add bx, 15 * 2
	lea di, [cs_reg+reg_len]
	push ax
	push cs
	pop ax
	call RegToStr
	pop ax
	pop bx

	add bx, 2 * 80
	lea di, [dx_reg + reg_len]
	push ax
	mov ax, dx
	call RegToStr
	pop ax

	
	add bx, 15 * 2
	lea di, [ip_reg + reg_len]
	push ax
	get_ip:
	lea ax, [get_ip]
	call RegToStr
	pop ax

	show_end:
	in al, 61h
	or al, 80h
	out 61h, al
	and al, not 80h
	out 61h, al

	mov al, 20h
	out 20h, al	

	pop es bx ax
	
	iret
	endp

db 0eah
oldbias dw 0h
oldsegm dw 0h

FrameStyle1: db '>>>| |<<<'


end start
