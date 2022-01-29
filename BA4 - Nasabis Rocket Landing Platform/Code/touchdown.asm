; file  touchdown.asm    target  ATmega128-4MHz-STK300
; author  Filip SLEZAK
; project  MCU Project Spring 2019

touchdown:
	rcall	read_temp
	cp	c0, b0
	brlo	PC+3 		 ; if not too hot return to main
	rcall	cool_down
	rjmp	touchdown
	ret

; temperature.asm
read_temp:	rcall	wire1_reset	 ; send reset pulse
    CA	    wire1_write, skipROM ; skip module identification
    CA     	wire1_write, convertT ; initiate temp conversion
    WAIT_MS	750

    rcall	wire1_reset
    CA	    wire1_write, skipROM
    CA	    wire1_write, readScratchpad

    rcall	wire1_read 	 ; read temperature LSByte
	mov		c1,a0
	rcall	wire1_read 	 ; read temperature MSByte
	mov		c0,a0

	lsl		c0			 ; conversion: float c0c1 to int c0
	lsl		c0
	lsl		c0
	lsl		c0
	MOVB	c0, 3, c1, 7
	MOVB	c0, 2, c1, 6
	MOVB	c0, 1, c1, 5
	MOVB	c0, 0, c1, 4 ; conversion end

	rcall	show_temp
	ret

; motor.asm
cool_down:				 ; 0x08*0xFF = 2040 pattern repetitions
	ldi		a0, 0x08
	ldi		a1, 0xFF
	MOTOR	0x50
	MOTOR	0x10
	MOTOR	0x80
	MOTOR	0xa0
	MOTOR	0x20
	MOTOR	0x40
	DLJNZ	a1, cool_down+2
	DLJNZ	a0, cool_down+1
	ret
