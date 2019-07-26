
; sets FM mode to FDC
.macro			SETFM

			lda	porta
			ora	#$20
			sta	porta

.endm

; sets MFM mode 
.macro			SETMFM

    			lda	porta
			and	#$df
			sta	porta
.endm

; waits 300 us
.macro			wait300us

			ldx	#3
			jsr	delay1

.endm

; waits 600 us
.macro			wait600us

			ldx	#6
			jsr	delay1

.endm

; waits 900 us
.macro			wait900us

			ldx	#9
			jsr	delay1

.endm

; sets riot count down timers
.macro			timeout

			lda	:1
			sta	tim64
			sta	t1024i
.endm

; fdc command
.macro			fdc

			lda	:1
			sta	command_register
.endm

; jump table entry 
.macro			JMPENTRY

			.byte :1,:2,<:3,>:3

.endm

; DRQ byte(s) to FDC 
; drq x   -> one byte drq
; drq x,y -> multiple bytes drq (x = count, y = byte)
.macro 			drq

	    ift :0 = 1	
			lda	:1
		    	bit	porta
			bpl	*-3
			sta	data_register
	    eif

	    ift :0 = 2	
			lda	:2
			ldx	:1
?_dq			bit	porta
			bpl	?_dq
			sta	data_register
			dex
			bne	?_dq
	    eif
.endm

