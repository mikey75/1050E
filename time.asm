;
; $Id: time.asm,v 1.2 2013/01/18 01:53:39 mikey Exp $
;

;
; delay, (x) * 100 micro seconds
;
delay1	ldy	#$12
	dey 
	bne	*-1 
	dex
	nop
	nop
	bne	delay1
	rts
;
; delay, (x) * 10 milliseconds
;
delay2	stx	ztmp
_dy1	ldy	#4
	sty	ztmp+1
_dy2	ldx	#$fa
	jsr	delay1
	dec	ztmp+1
	bne	_dy2
	dec	ztmp
	bne	_dy1
	rts
;
; delay, (x) * 5 + 12 micro seconds
;
delay3	dey 
	bne	*-1 
	rts

