; general.asm

.macro PRINTFL
	CA		lcd_pos, @0
	PRINTF	LCD
.endmacro

.macro MOTOR
	OUTI PORTD, @0
	WAIT_MS	1
.endmacro

.macro	DLJNZ ; DJNZ Long ; arg: reg, label
	dec		@0
	brne	PC+2
	rjmp	PC+2
	rjmp	@1
.endmacro
