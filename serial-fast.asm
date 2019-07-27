
		        .local fast

send_ack		ldx	#'A'
			jmp	sendbyte 
send_nak 		ldx	#'N'
			jmp	sendbyte 
send_compl		ldx	#'C'
			jmp	sendbyte 
send_error		ldx	#'E'
			jmp	sendbyte 

; fast send to serial, bit time 13-14 cycles

send_to_serial		;LDX	#6
			;JSR	delay1
			lda	portb
			lsr	@
			tay

			ldx	#0		; init checksumming
			stx	cksum

; send $count bytes from $where to serial

sendbuf			clc		
			lda	(where,X)
			sta	0
			adc	cksum
			adc	#0
			dec	portb
			sta	cksum
			lsr	0
			nop
			tya
			rol 	@
			sta	portb
			lsr	0,X
			tya
			rol 	@
			sta	portb
			lsr	0,X
			tya
			rol 	@
			sta	portb
			lsr	0,X
			tya
			rol 	@
			sta	portb
			nop
			lsr	0,X
			tya
			rol 	@
			sta	portb
			lsr	0,X
			tya
			rol 	@
			sta	portb
			lsr	0,X
			tya
			rol 	@
			sta	portb
			lsr	0,X
			tya
			rol	@
			sta	portb
			nop
			nop
			lda	portb
			ora	#1
			sta	portb
			inc	where
			cmp 	0
			dec	count
			bne	sendbuf

			ldx	#5
			jsr	delay1
			ldx	cksum		; send checksum
; send one byte (in x)
sendbyte		lda	portb
			ora	#1
			sta	portb
			lsr	@
			tay
			dec	portb
			nop
			nop
			txa
			lsr 	@
			tax
			tya
			rol 	@
		    	sta	portb
			txa
			lsr 	@
			tax
		    	tya
			rol 	@
			sta	portb
			txa
			lsr 	@
			tax
			tya
			rol 	@
			sta	portb
			txa
			lsr 	@
			tax
			tya
			rol 	@
			sta	portb
			nop
	    		txa
			lsr 	@
			tax
			tya
			rol 	@
			sta	portb
			txa
			lsr 	@
			tax
			tya
			rol 	@
			sta	portb
			txa
			lsr 	@
			tax
			tya
			rol 	@
			sta	portb
			txa
			lsr 	@
			tax
			tya
			rol 	@
			sta	portb
			nop
			nop
			lda	portb
			ora	#1
			sta	portb
			rts

			.align $100,$ff
cherr			jmp	chkserr

read_from_serial	ldx 	modifier 
		;	lda	#$ff
		;	sta	t1024i
			lda	#0
			tay
			sty	cksum		; init checksumming

; reads $count  bytes from serial and puts at $where
readbuf			;bit	porta
			;bvc	cherr
			bit	portb
			bvc	readbuf		;not taken = 3c
			nop
			nop
			pha
			pla
			cmp 	0
			cpx	portb	; b0	;4c		; 22 cykl od startbita - czyli jestem w polowie bitu 0
			ror	@		;2c
			pha
			pla	
			nop
			cpx	portb	; b1			; 13 cykli (bittime) od popezedniego bita - czyli w polowie bitu 1
			ror	@
			pha
			pla
			nop
			cpx	portb	; b2
	    		ror	@
			pha
			pla
			nop
			cpx	portb	; b3
			ror	@
			cmp 	0 
			cmp 	0
			nop
			cpx	portb   ;b4
			ror	@
			pha
			pla
			nop
			cpx	portb   ;b5
			ror	@
			pha
			pla
			nop
			cpx	portb	;b6
			ror	@
			cmp 0
			cmp 0
			nop
			cpx	portb	;b7
			ror	@
			sta	(where),y
			iny
			cpy	count
			bne	readbuf

			ldx	modifier
readbyte		bit	portb
			bvc	readbyte		;not taken = 3c
			nop
			nop
			pha
			pla
			cmp 	0
			cpx	portb	; b0	;4c		; 22 cykl od startbita - czyli jestem w polowie bitu 0
			ror	@		;2c
			pha 
			pla
			nop	
			cpx	portb	; b1			; 13 cykli (bittime) od popezedniego bita - czyli w polowie bitu 1
			ror	@
			pha
			pla
			nop
			cpx	portb	; b2
	    		ror	@
			pha
			pla
			nop
			cpx	portb	; b3
			ror	@
			cmp 	0
			cmp 	0
			nop
			cpx	portb   ;b4
			ror	@
			pha
			pla
			nop
			cpx	portb   ;b5
			ror	@
			pha
			pla
			nop
			cpx	portb	;b6
			ror	@
			cmp	0
			cmp 	0
			nop
			cpx	portb	;b7
			ror	@
;			nop
			sta	reg_a		; reg_a = chksum

			ldy	#0
calcks			lda	(where),y	; calculate checksum
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

chkserr     		lda 	#$40
	 		sta 	error
			rts


		        .endl	


