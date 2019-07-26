.macro	SETFM
	lda	porta
	ora	#$20
	sta	porta
.endm

.macro	SETMFM
    	lda	porta
	and	#$df
	sta	porta
.endm

.macro	wait300us
	ldx	#3
	jsr	delay1
.endm

.macro	wait600us
	ldx	#6
	jsr	delay1
.endm

.macro	wait900us
	ldx	#9
	jsr	delay1
.endm

.macro	timeout
	lda	:1
	sta	tim64
	sta	t1024i
.endm

.macro	fdc
	lda	:1
	sta	command_register
.endm

.macro	JMPENTRY
	dta b(:1,:2,<:3,>:3)
.endm

.macro 	drq
; drq ile co

    ift :0 = 1
	lda	:1
	bit	porta
	bpl	*-3
	sta	data_register
    eif

    ift :0 = 2
	lda	:2
	ldx	:1
?tmplbl	bit	porta
	bpl	*-3
	sta	data_register
	dex
	bne	?tmplbl
    eif
.endm

