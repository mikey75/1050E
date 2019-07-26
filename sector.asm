;
; $Id: sector.asm,v 1.2 2013/01/18 01:53:39 mikey Exp $
;

wrsector		sta	sector_register

_ws1			ldx	#0
			lda	#$e6
			sta	t1024i

			fdc	#$a2	; sector write + side compare

_ws2			lda	sekbuf,x
			eor	#$ff
_ws3			bit	porta
			bvc	_ws10
			bpl	_ws3
			sta	data_register
			lda	tim64
			inx
			cpx	percom+7
			bne	_ws2

			lda	#1
_ws4			bit	status_register
			bne	_ws4
			lda	status_register	; update status (by reading the register)
			lda	#0
			rts

_ws10			lda	status_register
			and	#1	;check for busy
			beq	_ws20

			timeout	#$e6
			bne	_ws2

_ws20			lda	tim64
			lda	status_register
			and	#$04	;check for lost data
			bne	_ws1

			lda	status_register
			lda	#1
			rts

; hardware read sector code
rdsector		sta 	sector_register

_r0			ldx	#0	;SET UP INDEX POINTER
			lda	#$e6
			sta	t1024i	;WT24E	;SET TIME OUT

			fdc	#$88

_r1			bit	porta
			bvc	_r10
			bpl	_r1
			lda	data_register
			eor	#$FF
			sta	sekbuf,x
			inx
			cpx	percom+7	;seklen
			bne	_r1

			lda	#1
_r2			bit	status_register
			bne	_r2

			lda	status_register
			eor	#$ff
			sta	status+1
			eor 	#$ff
			and	#%00101000	; check for crc/ddm 
			beq	_r3

			lda	#1	;error
			rts

_r3			lda	#0	;no error
			rts

_r10			lda	status_register
			and	#1
			beq	_r11
			timeout	#$E6
			bne	_r1 ;jmp

_r11			lda	tim64	; reset timer
			lda	status_register
			and	#4	;CHECK FOR LOST DATA
			bne	_r0

			lda	status_register
			eor	#$ff
			sta	status+1	; update status[1]

			lda	#1	; error
		    	rts

; read sector handler 
read_sector		jsr	chkl 	;send ack/nak for sector number

			lda	#4
			sta	retries

			jsr	calc

			bit	status_register
			bmi	rerror		; not rdy
			jsr	tmoton

_rs			bit	status_register
			bmi	rerror		; door open
			jsr	seek
			bne	rerror		; seek error

			lda	sektor
			jsr	rdsector
			bne	readerr

			jsr	send_compl
			jsr	sndsek
			lda	#0		; no error
			rts

readerr			jsr	restore
			dec	retries
			bne	_rs

rerror			jsr	send_error		; send 'E'
			jsr	sndsek
			lda	#1			; indicate eror
			rts

; write sector handler
write_sector		jsr	chkl
			jsr	chkb
			mwa	#sekbuf where
			jsr	read_from_serial

			wait900us	;???

			bit	error	; error from sio?
			bvs	wrerror

		    	jsr	send_ack

			lda	#4 
			sta	retries

			jsr	calc

			bit	status_register
			bmi 	wrerror
			jsr	tmoton

_wr			bit	status_register
			bmi 	wrerror ; door open
			bvs	wrerror	; write protect

			jsr	seek
			bne	wrerror

			lda	sektor
			jsr	wrsector

			bne	wrerr

			;clrb 	status #%10111011
			jsr	send_compl
			lda	#0
			rts

wrerr			jsr	restore
			dec 	retries
			bne	_wr

wrerror			jsr 	send_error
			lda	#1
			rts


; --- helper functions --; 

; send sector to sio

sndsek			jsr	chkb
			mwa	#sekbuf where
			jsr 	send_to_serial
			rts

; set data length according to bootsec or not

chkb			lda	daux2
			bne	no
			lda	daux1
			and	#%11111100
			bne	no
			mva 	#$80 count
			rts
no			mva	percom+7 count ;seklen count
			rts

; check if sector number is legal for given configuration
; so you won't try to read sector $400 on a DD disk etc

chkl			lda	daux1
			clc
			ora	daux2
			beq	wrong
;
			lda	percom+3 ;spt
			cmp	#26		; enhnced?
			beq	chk_ed

			ldx	#$d0		; else must be - max $2d0 sectors
			ldy	#$02
			bne	chk	;jmp
;
chk_ed			ldx	#$10		; in enhanced density $410 sectors
			ldy	#$04
;
chk			sec
			txa
			sbc	daux1
			tya
			sbc	daux2
			bcc	wrong		; wrong sector number
			jsr	send_ack
			rts
;
wrong			jsr	send_nak	; send nak
			pla
			pla
			lda	#1
			rts


; convert absolute sektor number to sector/track pair
; updates sektor and track 

calc			mvy	daux1 ztmp
			mvy	daux2 ztmp+1
			mvy	#0 track
			sty	sektor
			iny
			jsr	suby

			lda	percom+3 	;spt
			cmp	#26		;enhanced
			bne	spt18

			ldy	#26
			bne	cal1 	 	; jmp

spt18			ldy	#18
cal1			jsr	suby 
			bcc	toomuch
			inc	track
			bcs	cal1
toomuch			inc	sektor
			rts

suby			sty	pom
			sec
			lda	ztmp
			sta 	sektor
			sbc	pom
			sta	ztmp
			lda	ztmp+1
			sbc	#0
			sta	ztmp+1
			rts


