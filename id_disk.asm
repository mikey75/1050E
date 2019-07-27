; CHECK DRIVE DOOR STATUS (FDC's RDY)

dskchg			bit	status_register
			bpl	ds1		;door closed 
			bit	door_flag
			bpl	dret		;still opened 
			lda	#0		;just opened 
			sta	door_flag
			jsr 	motor_off
			rts

ds1			bit	door_flag
			bmi	dret		;still closed
			lda	#$ff		;just closed
			sta	door_flag

			jsr	tmoton
			jsr	ident
dret			rts

; IDENT DISKETTE 
ident			jsr	restore

			SETFM			; try MFM first
			jsr	rdadr
			beq 	single

			SETMFM			; try FM next
			jsr	rdadr
			bne	single		; NO FM NO MFM we need to assume

			lda 	idfield+3	; check ED vs DD
			beq	enhanc


; DOUBLE DENSITY SELECT
double			lda	#18
			sta	percom+3 	;spt
			lda	#0		; sector $100 bytes
			sta	percom+7 	;seklen
			mva	#4 percom+5	;MFM
			mva	#1 percom+6
			jsr	set_percom
dperc			lda	status
			ora	#%00100000
			and	#%01111111
			sta	status
			mva	#$4e gapbyte
			mva	#156 pregap
			mva	#22 idgap
			mva	#22 datagap
			mwa	#skew_dd skew
			lda	#$df
			and	porta
			sta	porta
			rts

; SINGLE DENSITY SELECT
single 			lda 	#18
			sta	percom+3 	;spt
			lda	#$80
			sta 	percom+7	;seklen
			mva	#0 percom+5	; FM
			mva	#0 percom+6
			jsr	set_percom
sperc			lda	status
			and	#%01011111
		    	sta	status
			mva	#0 gapbyte
			mva	#78 pregap
			mva	#15 idgap
			mva	#17 datagap
			mwa	#skew_sd skew
			lda	#$20
			ora	porta
			sta	porta
			rts

; MEDIUM DENSITY SELECT
enhanc			mva	#26 percom+3 	;spt
			mva	#128 percom+7	;seklen
			mva	#4 percom+5
			mva	#0 percom+6
			jsr	set_percom
eperc			lda	status
			and	#%11011111
			ora	#%10000000
			sta	status
			mva	#$4e gapbyte
			mva	#156 pregap
			mva	#49 idgap
			mva	#22 datagap
			mwa	#skew_ed skew
			lda	#$df
			and	porta
			sta	porta
			rts
; set common part of the percom
set_percom		mva 	#40 percom
		    	mva 	#0 percom+1
			sta	percom+2	; msb spt
		    	sta	percom+4	; sides
			sta	percom+8
			sta	percom+9
			sta	percom+10
			sta	percom+11
			rts

; READ ADDRESS (SECTOR HEADER)
rdadr			lda	#6
			sta	reseeks

ra0			ldx	#0

			timeout	#$d0
			fdc	#readaddr

ra1			bit	porta
			bvc	ra4
			bpl	ra1
			lda	data_register
			sta	idfield,X
			lda	tim64
			inx
			cpx	#6
			bne	ra1

			lda	#1
			bit	status_register
			bne	*-3 

			lda	#8	; crc error?
			bit	status_register
			beq	raok

			dec	reseeks ; crc error - try again
			bne	ra0

ra5			lda 	#1 
			rts

ra4			lda	timerdisable
			dec	reseeks
			beq	ra5	; kuniec, error

			timeout #$d0
			jmp	ra1
;
raok			lda	#0
			rts
