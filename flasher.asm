; flasher - this will be compiled separately at $200
; and copied to and run from ram @200 by firmware
; flasher can only program 8 2k banks at one go.
; so if you want to program whole 64k firmware area
; you need to
; load 16k to ram - run flasher with erase, program 16k
; load 16k to ram - run flasher without erase, new rom offset
; there will be vectors for those


	;		icl 'wormfood.asm'

			opt h-
			org $200

rambank_select		equ	0x0600		;xram bank select register
rombank_select		equ	0x0680		;xrom bank select register
xram			equ	0x0800		;banked xram window
xrom			equ	0x1000		;banked xrom window

src			equ	$32 ;(2)
dst			equ	$34 ;(2)
ile			equ	$36 
r1			equ	$37

.macro			rombank 
			lda :1
			sta rombank_select
.endm

.macro 			rambank
			lda :1
			sta rambank_select
.endm

; first erase first 64k of rom	(rombank x = phys address *2 / 1024) 
; so adr 0 i rombank 0 adr 4000 is rombank 8 adress 6 is rombank 12 etc 

;fl_erase
			rombank #0	; 0x0000
			jsr era_bank
			rombank #8	; 0x4000
			jsr era_bank
			rombank #$c	; 0x6000
			jsr era_bank
			rombank #$10	; 0x8000
			jsr era_bank
			rombank #0
			mva #$f0 $f555

; program 16k 
;fl_noerase	
			lda #8		; ile 2k bankow
			sta ile

			rombank #0 ; bank startowy romu (dst) bedzie od 0x0000 (sektor 0+)
			sta romb
			rambank #2 ; bank startowy na ram (zrodlo) bedzie od 0x1000 (sektor 16+)
			sta ramb

l1			lda <xrom
			sta dst
			lda >xrom
			sta dst+1

			lda <xram
			sta src
			lda >xram
			sta src+1

			lda ramb
			sta rambank_select
			lda romb
			sta rombank_select

;2k bank flash			
			ldy #0
l0			lda #0
			mva #$aa $f555
			mva #$55 $faaa
			mva #$a0 $f555

			lda (src),y
			sta (dst),y 

?w			lda (dst),y
			and #%01000000
			sta r1
			lda (dst),y
			and #%01000000
			cmp r1
			bne ?w

			iny
			bne l0

			inc src+1
			inc dst+1
			lda dst+1
			cmp >xrom+$800
			bne l0
; end 2k 
			inc romb
			inc ramb
			dec ile
			bne l1
;
; done
			rombank #0
;			jmp (reentry) ; reenter main
			jmp ($fffc) ; reset cpu/drive
			rts

era_bank		mva #$aa $f555
			mva #$55 $faaa
			mva #$80 $f555
			mva #$aa $f555
			mva #$55 $faaa
			mva #$30 xrom
			jsr wait
			rts

wait			lda xrom
			and #%01000000
			sta r1
			lda xrom
			and #%01000000
			cmp r1
			bne wait
			rts
romb			org *+1
ramb			org *+1
