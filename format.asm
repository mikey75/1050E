;
; $Id: format.asm,v 1.3 2013/01/19 00:23:03 mikey Exp $
;

; format according to percom
format
	jsr	send_ack
form	jsr	doformat
	beq	good

	lda	#0
	sta	sekbuf
	sta	sekbuf+1

good	mwa	#sekbuf where
	mva	percom+7 count ;seklen count
	jsr	send_to_serial

	lda	#0
	rts

; format enhanced 0x22
format_enh 

	jsr	send_ack
	jsr	enhanc
	jmp	form


; custom US format 0x66
custom_format

	jsr	send_ack

	mwa	#percom where
	mva	#128 count
	jsr	read_from_serial
	lda	error
	bvs	toobad
	wait300us
	jsr	send_ack
	jsr	chkprc
	mwa	#percom+12 skew
	jmp 	form

; check and set percom
chkprc	lda	percom
	cmp	#40
	bne	nn3

nn0	lda	percom+3
	cmp	#18
	bne	nn1
;
	lda	percom+5
	bne	nn1
;
	lda	percom+7
	cmp	#128
	bne	nn1
;

	jsr	sperc
;	jsr	send_compl
;	lda	#0
	rts
;
nn1	lda	percom+3
	cmp	#26
	bne	nn2

	lda	percom+5
	and	#4
	beq	nn2
;
	lda	percom+7
	cmp	#128
	bne	nn2
;

	jsr	eperc	; set the percom
;
;	jsr	send_compl
;	lda 	#0
	rts
;
nn2	lda	percom+3
	cmp	#18
	bne	nn3
;
	lda	percom+5
	and	#4
	beq	nn3
;
	lda	percom+6
	cmp	#1
	bne	nn3
	lda	percom+7
	bne	nn3

	jsr	dperc		; set percom
;	jsr	send_compl
;	lda	#0
	rts
;
nn3	jsr	send_error
	lda	#1
	rts

toobad	jsr	send_nak
	lda	#1
	rts

; TODO	przepisac 12 bajtow auxbuf do percom
;	przepisac 12+ bajtow do przeplot
;	wywolac format

doformat

; prepare bad sector buffer to send 

	ldx	#0
	lda	#$ff
fill	sta	sekbuf,x
	inx
	bne	fill

	mva	#0 track
f1	bit	status_register
	bmi	ferror	; door open
;	bvs	ferror	; write protect
	jsr	tmoton

	ldx	#$c0
	jsr	delay3

	lda	#1
	bit	status_register
	bne	*-3

	jsr	seek
	lda	error
	bne	ferror

	ldx	#$c0
	jsr	delay3

	lda	#1
	bit	status_register
	bne	*-3

	jsr	write_track
	bne	ferror

	ldx	#$c0
	jsr	delay3

	lda	#1
	bit	status_register
	bne	*-3

	jsr	verify_track; _mfm
	bne	ferror

	inc	track
	lda	track
	cmp	#40
	bne	f1

	lda	#1
	bit	status_register
	bne 	*-3

	jsr	ident		; na koniec zidekuj dysk aby zaktualizowac status i percom
	jsr	send_compl
	lda	#0
	rts

ferror	jsr	send_error
	lda	#1
	rts


write_track

	lda	#16
	sta	tim64i

	ldy	#0

	fdc	#writetrk ;$f0

	drq	gapbyte
	drq	gapbyte
	drq	pregap gapbyte	; PREINDEX GAP

	lda	#201	; 205 ms (one disk revolution time @288 rpm is 208 ms )
	sta	t1024i

t4	drq	idgap gapbyte	; INDEX GAP

	lda	percom+5 	;mfmflag
	and	#4
	beq	t2

	; if mfm
	drq	#12 #0		; MFM PRE ID RECORD GAP
	drq	#3 #$f5
	; endif

t2	drq	#$fe		; ID RECORD MARK

	drq	track
	drq	#0
	drq	"(skew),y"
	drq	percom+6 	;sector_len
	drq	#$f7		; CRC

	drq	datagap gapbyte ; DATA GAP

	lda	percom+5 ;mfmflag
	and	#4
	beq	t3

	; if mfm
	drq #12 #0		; MFM DATAGAP
	drq #3 #$f5
	; endfi

t3	drq	#$fb		; DATA MARK
	drq	percom+7 #$ff	;seklen #$ff	; SECTOR DATA
	drq	#$f7		; CRC

	iny
	cpy	percom+3 	;sectorcount 
	beq	endtr
	jmp	t4

endtr	lda	#1
	ldx	gapbyte		; write gap byte until timer tick (timer fires just few ms before end of a disk revolution)
t23	bit	porta
	bpl	t24
	stx	data_register
t24	bit	status_register
	bne	t23

	lda	#0
	rts

; verify track
verify_track

	ldy #0
        lda	#$ff
        sta t1024i

ver0	lda (skew),y 
        sta sector_register 
        ldx percom+7	;seklen

        fdc #$88

v1  	bit porta
        bvc failure 
        bpl v1 
        lda data_register 
        cmp #$FF
        bne failure 
        dex 
        bne v1

        lda #1
        bit status_register 
        bne *-3 

; now status register must be clean of crc and rnf flags i.e must be 0
; otherwise sector is bad

        lda status_register
        bne failure

        iny
        cpy percom+3 
        bne ver0
        lda #0
        rts 

failure FDC #forceirq	;$d0 	; force interrupt

; wait busy off
wb_ 	lda status_register 
	lsr @
	bcs wb_
        lda #1
	rts

skew_ed		.byte 1,3,5,7,9,11,13,15,17,19,21,23,25,2,4,6,8,10,12,14,16,18,20,22,24,26
skew_dd		.byte 18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
skew_sd		.byte 17,15,13,11,9,7,5,3,1,18,16,14,12,10,8,6,4,2
