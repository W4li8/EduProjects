; file  main.asm    target  ATmega128-4MHz-STK300
; authors  Lucas BOST, Filip SLEZAK
; project  MCU Project Spring 2019

; Interrupt Vector Table
.org 0x00
	rjmp	reset
.org INT0addr
	rjmp	inc_temp_max
.org INT1addr
	rjmp	dec_temp_max
.org INT3addr
	rjmp	reset
.org 0x30

.include "macros.asm"
.include "definitions.asm"

; Interrupt Service Routines
inc_temp_max:
	inc		b0
	rcall	show_temp
	WAIT_MS 150
	reti

dec_temp_max:
	dec		b0
	rcall	show_temp
	WAIT_MS 150
	reti

.include "lcd.asm"
.include "printf.asm"
.include "wire1.asm"

; LCD update
show_temp:
	PRINTFL $0 ; cursor to first line
.db "T=",FDEC,c,"C vs MAX=",FDEC,b,"C",CR,0  ;
	ret

reset:
	LDSP	RAMEND
	rcall	LCD_init   ; LCD
	rcall	wire1_init ; Temperature Sensor
	OUTI	DDRD, 0xF0 ; Motor

	ldi		b0, 0x19
	sub		c0, c0
	rcall	show_temp  ; LCD Initialization

	sei
	OUTI	EIMSK, 0x0B; Buttons

	OUTI	DDRE, 0x02 ; LED Matrix
	rcall	LED_Matrix0; LED Matrix Reset
	OUTI 	ADCSR, (1<<ADEN)+6
	OUTI	ADMUX, GP2_AVAL	; Distance Sensor

	rjmp init

.include "general.asm"
.include "landing.asm" ; not me
.include "touchdown.asm"

; Main Program
init:
	PRINTFL $40
.db "   SET MAX T!   ",CR,0
	WAIT_MS 7000
	OUTI	EIMSK, 0x08
	PRINTFL $40
.db "   RESET ONLY   ",CR,0
	WAIT_MS 3000
main:
	PRINTFL $40
.db	"    LANDING     ",CR,0
	rcall 	landing
	WAIT_MS 3000
	PRINTFL $40
.db "   TOUCHDOWN    ",CR,0
	rcall 	touchdown
stop:
	PRINTFL	$40
.db "  UFO IS COOL!  ",CR,0
	WAIT_MS 2000
	PRINTFL $40
.db	"    THE END     ",CR,0
loop:
	rjmp loop ; endless loop, waiting for reset
