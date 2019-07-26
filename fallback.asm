
; fallback 
; this is the only place where you can flash the drive from SIO
; other than that - flash and ram commands are unavailable
; so you won't accidentally brick the drive when doing normal SIO stuff.
; the only way to get here is at the beginning of the drive boot.
; procedure 

; 1. power off the drive 
; 2. remove any disks
; 3. CLOSE THE DRIVE DOOR (!!!IMPORTANT!!!)
; 4. power on the drive.
; 5. OPEN THE DOOR 
; 6. run flasher.

			.local fallback

riot			equ	0x700		; riot base address
porta			equ	riot		; data register port a
portb			equ	riot+0x02	; data register port b
tim64			equ	riot+0x16	; timer : 64
t1024i			equ	riot+0x1f	; timer : 1024 interrupt enable
rambank_select		equ	0x0600		;xram bank select register
xram			equ	0x0800		;banked xram window
jumper			equ	$61 ;(2); $62

ztmp			equ 	$f0 ; (3) $f1 $f2 
error			equ	$f3 ; (1)
where			equ	$f4 ; (2) $f5 
count			equ	$f7 ; (1)
cksum			equ	$f8 ; (1)
;reg_a			equ	$f9 ; (1)

cmd_frame		equ	$fa ; (5) $fb $fc $fd $fe $ff
dunit			equ	cmd_frame
dcommand		equ	cmd_frame+1
daux1			equ	cmd_frame+2
;daux2			equ	cmd_frame+3
;crc			equ	cmd_frame+4


main		    	jsr	getcmd
			jmp	main

getcmd			lda	#2
			bit	portb
			bne	ret
			bmi	*+3
ret			rts

			mva	#4 count
			mwa	#cmd_frame where
			jsr	read_from_serial ; read 4 bytes with time out
wait_end		bit	portb		 ; wait until command on zero
			bmi	wait_end
			bit	error
			bvs	chksumerr
			lda	porta
			and	#3		; drive number
			tax			; to x reg
			lda	drvnr,x		; drive number same
			cmp	dunit	;cmd_buf		; as in command frame[0]
			bne	notme		; no, error

			ldx	#0
search			lda	cmds,x
			cmp	dcommand	;cmd_buf+1
			beq	execute
			inx
			cpx	#cmds_len
			bcc	search

			lda	status
			ora	#1
			sta	status
			jsr	send_nak	;lda	status
notme			rts

execute			lda	lows,x
			sta	jumper
			lda	highs,x
			sta 	jumper+1
			jmp	(jumper)

chksumerr		lda	status
			ora 	#2
			sta	status
			rts

go_putmem;rombank #0
			jsr 	put_memory
			rts

go_run	;rombank #0
			jsr 	run_memory
			rts

drvnr			.byte 	$33,$32,$34,$31,$ff,$00
cmds			.byte 	$f0,$f2
cmds_len		equ 	(*-cmds)
;
lows			.byte <go_putmem, <go_run ;dta l(go_putmem),l(go_run)
highs			.byte >go_putmem, >go_run ;dta h(go_putmem),h(go_run)


put_memory		bit 	daux1
			bpl	dalej	; cmp #$80; bcc dalej
			jsr	send_nak
			rts
;
dalej			jsr	send_ack

			lda	daux1	; podzielimy przez 8 da nam nr banku
			lsr	@
			lsr 	@
			lsr 	@
			sta	rambank_select
;
			lda 	daux1	; page moze byc od 0 do 7
			and 	#%00000111
			clc
			adc	>xram
			sta	where+1
			mva	<xram where	; where now points to bank+page[0]

			mva	#0 count
			jsr	read_from_serial

			wait900us
;
			bit	error
			bvs	errrr
;
			jsr	send_ack
			jsr	send_compl
			rts

errrr;			status_cksum_err
			jsr	send_error
			rts
; run program @adr in ram
; daux1,daux2 = lsb,msb
run_memory		jsr 	send_ack 
			jmp 	(daux1)
			rts

; stock serial routine 
			.align $100,$ff

sendbyte		sta	ztmp		; save char
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



readbyte		sty	ztmp+2		; save x reg
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

read_from_serial	timeout #$ff		;lda	#$ff
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

errstat 		lda 	#$40
norerr 			sta 	error
			lda	tim64		; reset timeout counter
			rts



send_ack		lda	#'A'
			jsr	sendbyte
			rts

send_nak 		lda	#'N'
			jsr	sendbyte
			rts

send_compl		lda	#'C'
			jsr	sendbyte
			rts

send_error		lda	#'E'
			jsr	sendbyte
			rts

delay1			ldy	#$12
			dey 
			bne	*-1 
			dex
			nop
			nop
			bne	delay1
			rts


    .endl
