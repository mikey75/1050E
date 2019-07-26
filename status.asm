;
; $Id: status.asm,v 1.3 2013/01/18 01:53:39 mikey Exp $
;

;
; 0x53 - send status to atari
;
send_status

	wait300us
	jsr	send_ack
	jsr	dforce

	; if door open, return status of a romdisk
	; TODO - return write protect bit

	lda	status_register
	sta	status+1

	lda	#$e0
	sta	status+2

	lda	#0
	sta	status+3
	sta	error

;	jsr	send_ack

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
;
; 0x3F - send pokey divisor to atari
;
send_divisor

	jsr	send_ack
	wait300us
	jsr	send_compl
	lda	#6
	jsr	sendbyte
	lda 	#6
	jsr	sendbyte
	lda	#0
	rts
