;
; $Id: serial-fast.asm,v 1.3 2013/01/19 00:23:03 mikey Exp $
;

    .local fast
send_ack		ldx	#'A'
			jmp	sendbyte ;jsr/rts
send_nak 		ldx	#'N'
			jmp	sendbyte ;jsr/rts
send_compl		ldx	#'C'
			jmp	sendbyte ;jsr/rts
send_error		ldx	#'E'
			jmp	sendbyte ;jsr/rts

; fast send to serial, bit time 13-14usec

send_to_serial		;LDX	#6
			;JSR	delay1
loc_0_ED01:		LDA	portb
			LSR	@
			TAY
			LDX	#0
			stx	cksum

loc_0_ED08:		CLC
			LDA	(where,X)
			STA	0
			ADC	cksum
			ADC	#0
			DEC	portb
			STA	cksum
			LSR	0
			NOP
			TYA
			ROL 	@
			STA	portb
			LSR	0,X
			TYA
			ROL 	@
			STA	portb
			LSR	0,X
			TYA
			ROL 	@
			STA	portb
			LSR	0,X
			TYA
			ROL 	@
			STA	portb
			NOP
			LSR	0,X
			TYA
			ROL 	@
			STA	portb
			LSR	0,X
			TYA
			ROL 	@
			STA	portb
			LSR	0,X
			TYA
			ROL 	@
			STA	portb
			LSR	0,X
			TYA
			ROL	@
			STA	portb
			NOP
			NOP
			LDA	portb
			ORA	#1
			STA	portb
			INC	where
			CMP 	0
			DEC	count
			BNE	loc_0_ED08
			LDX	#5
			JSR	delay1
			LDX	cksum

sendbyte:		LDA	portb
			ORA	#1
			STA	portb
			LSR 	@
			TAY
			DEC	portb
			NOP
			NOP
			TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
		    	STA	portb
			TXA
			LSR 	@
			TAX
		    	TYA
			ROL 	@
			STA	portb
			TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
			STA	portb
			TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
			STA	portb
			NOP
	    		TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
			STA	portb
			TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
			STA	portb
			TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
			STA	portb
			TXA
			LSR 	@
			TAX
			TYA
			ROL 	@
			STA	portb
			NOP
			NOP
			LDA	portb
			ORA	#1
			STA	portb
			RTS
			.align $100,$ff
cherr	jmp	chkserr

read_from_serial:

			ldx 	modifier ;#$3f
		;	lda	#$ff
		;	sta	t1024i
			lda	#0

			tay
			sty	cksum
wb:			;bit	porta
			;bvc	cherr
			BIT	portb
			BVC	wb		;not taken = 3c
			nop
			nop
			pha
			pla
			cmp 0
			CPX	portb	; b0	;4c		; 22 cykl od startbita - czyli jestem w polowie bitu 0
			ROR	@		;2c
			pha
			pla	
			nop
			CPX	portb	; b1			; 13 cykli (bittime) od popezedniego bita - czyli w polowie bitu 1
			ROR	@
			pha
			pla
			nop
			CPX	portb	; b2
	    		ROR	@
			pha
			pla
			nop
			CPX	portb	; b3
			ROR	@
			cmp 0 
			cmp 0
			nop

			CPX	portb   ;b4
			ROR	@
			pha
			pla
			nop


			CPX	portb   ;b5
			ROR	@
			pha
			pla
			nop

			CPX	portb	;b6
			ROR	@
			cmp 0
			cmp 0
			nop

			CPX	portb	;b7
			ROR	@
			sta	(where),y	;sta	(bufptr),y
			iny
			cpy	count
			BNE	wb

; cheksuma		
			ldx	modifier
wb2			BIT	portb
			BVC	wb2		;not taken = 3c
			nop
			nop
			pha
			pla
			cmp 0

			CPX	portb	; b0	;4c		; 22 cykl od startbita - czyli jestem w polowie bitu 0
			ROR	@		;2c
			pha 
			pla
			nop	

			CPX	portb	; b1			; 13 cykli (bittime) od popezedniego bita - czyli w polowie bitu 1
			ROR	@
			pha
			pla
			nop

			CPX	portb	; b2
	    		ROR	@
			pha
			pla
			nop

			CPX	portb	; b3
			ROR	@
			cmp 0
			cmp 0
			nop

			CPX	portb   ;b4
			ROR	@
			pha
			pla
			nop
			CPX	portb   ;b5
			ROR	@
			pha
			pla
			nop

			CPX	portb	;b6
			ROR	@
			cmp	0
			cmp 	0
			nop

			CPX	portb	;b7
			ROR	@
;			nop
			sta	reg_a	;sta	(bufptr),y


; dodaj jeszcze 1 bajt do czeksumy 

;			ldy	count
;			dey
;			lda	sekbuf,y	;LDA	(bufptr),y
;			CLC
;			ADC	reg_a
;			ADC	#0
;			STA	reg_a

			ldy	#0
calcks			lda	(where),y
			clc
			adc	cksum
			adc	#0
			sta 	cksum
			iny
			cpy	count
			bne	calcks
			lda	cksum
			eor	reg_a
			bne	chkserr
			sta	error
			rts
chkserr 
	    		lda 	#$40
	 		sta 	error
			rts


    .endl


