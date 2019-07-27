send_status		wait300us
			jsr	send_ack
			jsr	dforce

			; TODO - if door open, return status of a romdisk (when done)
			; TODO - return write protect bit		

			lda	status_register
			sta	status+1

			lda	#$e0
			sta	status+2

			lda	#0
			sta	status+3
			sta	error

;			jsr	send_ack

			wait300us
			jsr	send_compl
    
		    	lda	#4
			sta	count

			lda	<status 
			sta	where
			lda	>status
			sta	where+1
			jsr	send_to_serial

		    	lda	#$53		; no error, return $53 so that main handler does not update status after status ;)
			rts

send_divisor		jsr	send_ack
			wait300us
			jsr	send_compl
			lda	#6		; 26.07.2019 - czemu 2 razy???
			jsr	sendbyte	
			lda 	#6
			jsr	sendbyte
			lda	#0
			rts
