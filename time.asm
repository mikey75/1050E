;
; delay, (x) * 100 micro seconds
;
delay1			ldy	#$12
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
delay2			stx	ztmp
d1			ldy	#4
			sty	ztmp+1
d2			ldx	#$fa
			jsr	delay1
			dec	ztmp+1
			bne	d2
			dec	ztmp
			bne	d1
			rts
;
; delay, (x) * 5 + 12 micro seconds
;
delay3			dey 
			bne	*-1 
			rts

