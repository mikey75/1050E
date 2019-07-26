;
; $Id: motor.asm,v 1.3 2013/01/19 00:23:03 mikey Exp $
;

; motor.asm this is mostly original stock 1050 motor stuff 
; I think it's pretty robust and reliable and needs no fundamental changes


; MOTOR OFF
motor_off

	lda	porta
	ora	#%00001000
	sta	porta

	lda	portb
	ora	#%00111100	; turn off all 4 coils
	sta	portb

	lda	status
	and	#%11101111
	sta	status
	rts

; MOTOR ON
motor_on

	lda	porta
	and	#%11110111
	sta	porta

	ldx	phase		; turn on coils for given phase
	lda	portb
	and	phase1,x
	sta	portb

	lda	#0
	sta	motor_timer
	sta	motor_timer+1

	lda	status 
	ora	#%00010000
	sta	status
	; wait for spinup
	ldx	#5
	jsr	delay2
	rts

; MOTOR ON IF NOT ON, RESET TIMER
tmoton

	lda 	porta
	and	#8
	beq	_tm
	jsr	motor_on

_tm	lda	#0
	sta	motor_timer
	sta	motor_timer+1
	rts

; DRIVE STARTUP SEQUENCE (trk0, 10 steps(5 trks), restore) aka BZIUM :)
bzium

	jsr	restore
	lda	#10
	jsr	dosteps		; make the steps

; RESTORE (SEEK TRACK 0)
restore

	jsr	dforce

	lda	#$ff
	sta	dir
	lda	#0
	sta	stepcnt
	sta	steps

_re1	lda	status_register
	and	#4
	beq	_re2
	jsr	hstep
	jmp	_re1		; on track 0 yet?

_re2	lda	phase		; in phase 4?
	cmp	#3
	beq	_re3
	jsr	hstep
	jmp	_re2		; on track 0, phase 4 ?

_re3	lda	#0
	sta	track_register
	sta	stepcnt		; and step counter

	ldx	#$c8		; 20 milli seconds delay
	jsr	delay1
	rts
;
; make half a step
; the	step motor runs a cyclus of 4 phases, equal to 2 tracks
;
hstep	jsr	dohstep		; make half a step
	jsr	force		; interrupt floppy command

	ldx	#$64		; 10 ms delay
	jmp	delay1
;
; do half a step
;
dohstep	inc	stepcnt		; incr counter
	lda	stepcnt
	cmp	#$78		; already 120 steps?
	bcs	steperr		; if so, something wrong
	lda	porta
	and	#8
	beq 	step

steperr	brk			; step error: motor off or too many steps

step	ldx	phase
	lda	phase1,x	; get mask for phase
	eor	#$ff		; invert
	tay
	bit	dir		; get step direction
	bpl	stepm		; for following phase
	inx			; step forward
	cpx	#4		; cyclus done?
	bne	step1
	ldx	#0		; if so, do it again
	beq	step1
stepm	dex			; step backward
	bpl	step1		; cyclus done?
	ldx	#3		; if so, do it again backward
step1	stx	phase		; save new phase
	tya			; reset old phase
	ora	portb
	and	phase1,x	; set new phase
	sta	portb
	rts

; SEEK TRACK
seek	jsr	force
	lda	track
	sec
	sbc	track_register
	bne	dosteps		; track reg differs from wanted track -> seek
	rts			; otherwise -> done


; make as many steps as value in accu
dosteps	bmi	dost1		; step backward?
	ldx	#1		; no, forward
	bpl	dostep1
dost1	ldx	#$ff		; backward
	eor	#$ff		; get two's complement
	clc
	adc	#1
dostep1 asl	@		; two times (2 phases/step)
	bpl	dostep2		; br if ok
	jsr	restore		; otherwise too many steps: restore
	mva	#$80 error
	rts

dostep2	sta	steps		; number of steps
	stx	dir		; direction

	mva	#0 stepcnt
dostep3	jsr	hstep		; make half a step
	dec	steps		; all done?
	bne	dostep3		; no, continue
	bit	dir		; backward step?
	bmi	chktrk		; br if so

	mva	#$ff steps
	mva	#0 stepcnt

	jsr	hstep		; same direction
	mva	#$ff dir
	jsr	hstep		; step backward
	mva	#0 steps
	sta	stepcnt
;
; set bit porta b4 (write precomp) on track > 20
;
chktrk
	lda	track
	sta	track_register
	cmp	#20		; greater then 20?
	bcc	ktr20		; no
	lda	#$10		; otherwise, set bit 4 of port a
	ora	porta
	bne	gtr20		; br always
ktr20	lda	#$ef		; reset bit 4 of port a
	and	porta		; for track less then 20
gtr20	sta	porta
	ldx	#$c8
	jsr	delay1		; 20 ms delay after seek
	ldx	#$c8
	jmp	delay1		; one more time seems to be necessary

;phase1 		.byte $fb,$f7,$ef
;phase4 		.byte $df,$57

phase1	.byte %11111011 ;$fb
	.byte %11110111	;$f7
	.byte %11101111	;$ef
phase4 	.byte %11011111 ;$df;
	.byte %01010111 ;$57

;
; force interrupt of any command on fdc
;
dforce	jsr	force
force	fdc	#forceirq

	ldx	#7
	dex
	bne	*-1 

	lda	#1
	bit	status_register
	bne	*-3

	rts
