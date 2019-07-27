
fail			brk

			; 6502 startup

start	    		cld
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
clrram			sta	$000,x
			sta	$100,x
			sta	$200,x
			sta	$300,x
			sta	$400,x
			sta	$500,x
			inx
			bne	clrram

			lda 	#0
			sta 	turbo_flag

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

			jsr	motor_off
			jmp 	mainloop
