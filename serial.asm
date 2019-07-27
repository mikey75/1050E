sendbyte_fast_tramp	jmp	fast.sendbyte

sendbyte		pha
			lda	turbo_flag
			bne	sendbyte_fast_tramp
			pla
			sta	ztmp		; save char
			sty	ztmp+1		; save checksum
			stx	ztmp+2		; save x

			ldy	#8		; send 8 bits
			lda	#$fe		; set start bit
			and	portb		; ...and send
			sta	portb
			inc	ztmp+2		; delay

sbyte1			ror	ztmp		; next data bit
			bcc	sbit0		; send '0' bit
			lda	#1		; send '1' bit if carry set
			ora	portb
			bne	sbit		; send bit
sbit0			lda	#$fe		; send '0' bit
			and	portb
			nop			; keep synchronous

sbit			ldx	#5		; send bit
			dex			; delay
			bne	*-1

			sta	portb		; to port
			dey			; done?
			bne	sbyte1

			ldx	#6		; delay for last bit
			dex 
			bne	*-1

			nop
			dec	ztmp+2		; delay
			lda	#1		; send stop bit
			ora	portb
			sta	portb

			ldx	#5		; delay for stop bit
			dex 
			bne	*-1

			ldx	ztmp+2		; restore x
			ldy	ztmp+1		; and y
			lda	ztmp		; and a
			rts			; done


;-----------------------------------------------------------------------
; readbyte - get one byte from serial
; sets error bit6 if timeout waiting for start bit
; and also breaks  out to main loop instead of cmd loop
; pla.pla 

readbyte	
			sty	ztmp+2		; save x reg
wsb			bit	porta		; wait for start bit
			bvc	err1		; data interrupt from floppy?
			bit	portb		; or data in at port 6 high?
			bvc	wsb		; no

			sec			; otherwise
			lda	#$80		; bit 7 mark for end

			ldx	#6		; wait 0.5 bit time
			dex 
			bne	*-1

w32b			ldx	#6		; wait 2/3 bit time
			dex			; to get first bit in the middle
			bne	*-1
			nop
			nop
			nop

			bit	portb		; bit 1 or 0?
			bvc	bit1
			clc			; got a zero
			bcc	nxtbit
bit1			sec			; got a one
			nop			; keep in same tempo as bcc
nxtbit			ror	@		; roll bit in result
			bcc	w32b		; already 8 bits?

			ldy	ztmp+2		; restore x reg
			rts

err1			pla 
			pla
			jmp 	errstat

;----------------------------------------------------------------------
; read bytes from serial port
; number of bytes in count/buffer address in where/where+1
; $80 for 128B, $0 for 256. 

read_from_serial	lda 	turbo_flag
			bne 	read_fast_tramp

			timeout #$ff		;lda	#$ff

			mva	#0 ztmp		;lda	#0		; reset checksum
			tay
						; sta	ztmp
; data byte
rnxtb			jsr	readbyte		; read byte

			sta	(where),y	; and store it
			clc			; add to checksum
			lda	ztmp
			adc	(where),y
			adc	#0
			sta	ztmp
			iny			; buffer pointer + 1
			dec	count		; job done?
			bne	rnxtb		; no, continue
; chksum
			jsr	readbyte	; yes, read checksum
			sta	cksum		;(where),y	; store
			lda	ztmp		; and compare with accumulated value
			eor	cksum		;(where),y
			beq	norerr		; br if ok
;			brk
errstat 	;	lda 	#$ff
		;	sta	turbo_flag
	    		lda 	#$40
norerr 			sta 	error
			lda	tim64		; reset timeout counter
			rts


;------------------------------------------------------------------
; send bytes from address pointed by where/where+1
; number of bytes in count
;
send_to_serial 		lda	turbo_flag
			bne	send_fast_tramp

		    	mva	#0 reg_a
			tay
; data		
send1			lda	(where),y	; add to checksum
			pha
			clc
			adc	reg_a		;sekbuf,x
			adc	#0
			sta 	reg_a
			pla
			jsr	sendbyte	; send byte
			iny			; buffer address + 1
			dec	count		; job done?
			bne	send1		; no, continue
; chksum
			lda 	reg_a
			jsr	sendbyte
			rts



; send 'C,N,E or A' to cpu
send_ack		lda	turbo_flag
			bne	send_ack_tramp
			lda	#'A'
			jmp	sendbyte
;			rts

send_nak 		lda	turbo_flag
			bne	send_nak_tramp 
			lda	#'N'
			jmp	sendbyte
;			rts

send_compl		lda	turbo_flag
			bne	send_compl_tramp
			lda	#'C'
			jmp	sendbyte
;			rts

send_error		lda	turbo_flag
			bne	send_error_tramp
			lda	#'E'
			jmp	sendbyte
;			rts


read_fast_tramp		jmp	fast.read_from_serial
send_fast_tramp		jmp	fast.send_to_serial
send_ack_tramp		jmp	fast.send_ack
send_nak_tramp		jmp	fast.send_nak
send_compl_tramp	jmp	fast.send_compl
send_error_tramp	jmp	fast.send_error
