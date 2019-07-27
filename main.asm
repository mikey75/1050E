;	  _  ___  ____   ___       
;	 / |/ _ \| ___| / _ \  ___ 
;	 | | | | |___ \| | | |/ _ \
;	 | | |_| |___) | |_| |  __/
;	 |_|\___/|____/ \___/ \___|
;                          
; 1050E Hardware by Sebastian Bartkowicz (Candle) - http://spiflash.org
; 1050E firmware by Michal Szwaczko (Mikey) - http://m.wirelabs.net
;
; Firmware Copyright (c) 2010-2012,2013,2019 Michal Szwaczko
;
			icl 	'wormfood.asm'		; usual wormfood :)
		    	opt	h- f+ o+

; ============================= BANK 0 ==================================

			org 	$f000,$0000		; bank 0

			icl	'fallback.asm'		; fallback minimal code to flash drive if main code toasted
    			icl	'sector.asm'
			icl	'status.asm'
			icl	'hwinit.asm'

			ert	* >$f7ff

; ============================== BANK 1 ==================================

			org	$f800,$0800

mainloop		lda	#2
			sta	rombank_select
			jsr	dskchg		; returns if door status didn't change
			jsr	wait4cmd	; returns if no cmd line low

			lda	porta 		; motor on?
			and	#8 
			bne	mainloop	; no, loop without timer

			ldx	#2		; yes, delay
			dex 
			bne	*-1 

			inw	motor_timer
			bne	mainloop
			jsr	motor_off		; if timer expires, stop motor
			jmp	mainloop

wait4cmd		lda	#2
			bit	portb
			bne	ret
			bmi	*+3 ;readcommand
ret			rts

; read command

			mva	#$bf modifier	; for speedsio need to tell command from data when doing bitbang
			mwa 	#cmd_frame where
			mva	#4 count
			jsr	read_from_serial

			bit	portb		 ; wait until command high
			bmi	*-3

			bit	error
			bvs	chksumerr
			mva	#$3f modifier

; indicate no checksum error to status

			lda	status
			and	#%11111101
			sta	status

			lda	porta
			and	#3
			tax
			lda	drvnr,x
			cmp	dunit
			bne	notme

; search the command in the command table 
	
			ldx	#0
search			lda	tab,x
			beq	unknown		; thats end of table condition, not notme condition
			cmp	dcommand
			beq	execute
			inx
			inx
			inx
			inx
			bne	search		;jmp

; indicate command unrecognized to status

unknown			lda	status
			ora	#1
			sta	status
			jsr	send_nak
notme			rts

; execute command 

execute			cmp	#$53		; if command was status dont indicate
			beq	_e0

; indicate command recognized to status

			lda	status
			and	#%11111110
			sta	status

_e0			lda	tab+1,x
			sta	rombank_select 

			lda	tab+2,x
			sta	jumper
			lda	tab+3,x
			sta 	jumper+1

; setup return address from handlers so that rts from the handler will always come back here 

			lda	>(_e1-1)
			pha
			lda	<(_e1-1)
			pha
			jmp	(jumper)

_e1		    	bne	_e2	; all command handlers return with A=0 or A=1, 1 means there was an error 

			lda	status
			and	#%11111011
			sta	status
			rts

_e2			cmp	#$53		; status returns with this code so we dont update anything
			beq	_e3

			lda	status		; indicate error to status
			ora	#%00000100
			sta	status
_e3			rts

chksumerr		lda	turbo_flag 	; toggle ultraspeed 
			eor	#$ff
			sta	turbo_flag

; indicate chcksum error to status

			lda	status
			ora 	#2
			sta	status
			rts

; command handlers jump table

tab			JMPENTRY $53,0,send_status
			JMPENTRY $52,0,read_sector
			JMPENTRY $3f,0,send_divisor
			JMPENTRY $50,0,write_sector
			JMPENTRY $4f,2,receive_percom
			JMPENTRY $4e,2,send_percom
			JMPENTRY $22,2,format_enh
			JMPENTRY $21,2,format
			JMPENTRY $66,2,custom_format
			JMPENTRY $0,0,0

; legal drive numbers 

drvnr			.byte $33,$32,$34,$31

; these are core modules, must be accessible from any bank so they must be here

			icl	'time.asm'
			icl 	'serial.asm'
			icl	'serial-fast.asm'
			icl	'motor.asm'

; IRQ handler for BRK - cycles motor on / motor off to signal that the drive has hanged

irq			lda	#2
			sta	ztmp
			jsr 	motor_on
			ldx	#10
			jsr	delay2
			jsr	motor_off
			ldx	#10
			jsr	delay2
			jsr	motor_on
			dec	ztmp
			bne	irq

			ert 	* > $fff0 

			org	$fffc,$0ffc

			.word 	start
			.word 	irq


;-------------------------- end of system address space --------------------------;

; bank  2

			org 	$1000,$1000

			icl	'format.asm'
			icl	'percom.asm'
			icl	'id_disk.asm'

			.ifdef  RELEASE
			dta 	c'1050E firmware by mikey'
			dta	c'1050E hardware by candle'
			.endif
