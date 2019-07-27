
; SEND PERCOM DATA TO ATARI
send_percom		jsr	send_ack
			wait300us
			jsr	send_compl
sendit			lda	#12
			sta 	count
			mwa	#percom where
			jsr	send_to_serial
			lda	#0
			rts

; GET CONFIG FROM ATARI
receive_percom		jsr 	send_ack
			lda	#12
			sta	count
			mwa	#percom where
			jsr	read_from_serial
			bit	error
			bvs	n3

; CHECK IF PERCOM CORRESPONDS TO KNOWN CONFIGURATION
check_percom		lda	percom
			cmp	#40
			bne	n3

n0			lda	percom+3
			cmp	#18
			bne	n1
;
			lda	percom+5
			bne	n1
;
			lda	percom+7
			cmp	#128
			bne	n1
;
			jsr	sperc
			jmp	epilog

n1			lda	percom+3
			cmp	#26
			bne	n2

			lda	percom+5
			and	#4
			beq	n2
;
			lda	percom+7
			cmp	#128
			bne	n2
;
			jsr	eperc		; set the percom
			jmp	epilog
;
n2			lda	percom+3
			cmp	#18
			bne	n3
;
			lda	percom+5
			and	#4
			beq	n3
;
			lda	percom+6
			cmp	#1
			bne	n3
			lda	percom+7
			bne	n3
			jsr	dperc		; set percom

epilog			ldx	#5
			jsr	delay1
			jsr 	send_ack
			ldx	#5
			jsr	delay1
			jsr	send_compl
			lda	#0
			rts
;
n3			wait300us
			jsr	send_error
			lda	#1
			rts

