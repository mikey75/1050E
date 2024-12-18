;
; $Id: hwinit.asm,v 1.3 2013/01/19 00:23:03 mikey Exp $
;
fail	brk

start
	; init stack and clear decimal
    	cld
	ldx	#$ff
	txs

	; riot tests
	lda	#$3c
	sta	pactl
	lda	#$38
	sta	porta
	lda 	porta
	and	#$3c
	cmp	#$38
	bne	fail

	lda	#$3d 
	sta	pbctl
	lda	#$3d
	sta	portb
	lda 	portb 
	and	#$3d 
	cmp	#$3d
	bne	fail

	; fdc tests
	fdc	#forceirq

	ldx 	#$15
	dex
	bne 	*-1

	lda	status_register 
	and	#1 
	bne	fail

	lda	#$55 
	sta	track_register
	sta	sector_register

	ldx	#$1e
	dex
	bne 	*-1

	eor	track_register
	bne	fail

	lda	#$55
	eor	sector_register
	bne	fail

	fdc	#$48	;step in, head load, steprate

	ldx	#$28
	jsr	delay1

	lda	status_register
	and	#1 
	beq	fail

	ldx	#$28
	jsr	delay1

	lda	status_register 
	and	#1 
	bne	fail

; if lever is closed during power up -> run fallback code 

	lda	status_register
	bmi	*+5
	jmp	fallback.main

; clear ram 

	lda	#0
	tax
?zozo	sta	$000,x
	sta	$100,x
	sta	$200,x
	sta	$300,x
	sta	$400,x
	sta	$500,x
	inx
	bne	?zozo
	lda #0
	sta turbo_flag
;	lda	#2
;	sta	rvalue
;
;?ccc	lda	rvalue
;	sta	rambank_select
;
;	lda	#0
;	tax
;?cc	;lda	rvalue
;	sta	$800,x
;	sta	$900,x
;	sta	$a00,x
;	sta	$b00,x
;	sta	$c00,x
;	sta	$d00,x
;	sta	$e00,x
;	sta	$f00,x
;	inx
;	bne	?cc
;
;	inc 	rvalue
;	lda	rvalue
;	cmp	#16
;	bne	?ccc

	; init drive

	ldx	#3
	stx	phase
	lda	phase4
	and	portb
	sta	portb
	jsr	tmoton
	lda	#0
	sta	track
	jsr	bzium

;	jsr	single			; set initial config 

	jsr	motor_off
	jmp 	mainloop
