;
; $Id: wormfood.asm,v 1.3 2013/01/19 00:23:03 mikey Exp $
;
; 1050E Hardware by Sebastian Bartkowicz (Candle) - http://spiflash.org
; 1050E firmware by Michal Szwaczko (Mikey) - http://m.wirelabs.net
;
; Copyright (c) 2010-2012 - all rights reserved and enforced.
;
; This source code and resulting binary is property of WireLabs Technologies, and Michal Szwaczko
; Duplication, modification, and distribution is subject to license available at mikey@wirelabs.net
;
; *** 1050E memory map - 4KB address space ***
;
; 0000-057F - RAM
; 0580-05FF - HD44870 

; 0600-067F - RAM BANK SELECT REGISTER
; 0680-06FF - ROM BANK SELECT REGISTER
; 0700-077F - RIOT registers
; 0780-07FF - WDC registers

; 0800-0FFF - RAM BANK (bank #0 at RESET)
; 1000-17FF - ROM BANK (bank #0 at RESET)
; 1800-1FFF - ROM

; 32k RAM - 16 2k banks - 128 pages
; 512k ROM -256 2k banks
; 2k = 8 pages
			icl 	'macros.asm'

; hardware locations
riot			equ	0x700		; riot base address
wdc			equ	0x780		; wdc controller base address

; hardware - 6532 RIOT
porta			equ	riot		; data register port a
pactl			equ	riot+0x01	; data direction register port a
portb			equ	riot+0x02	; data register port b
pbctl			equ	riot+0x03	; data direction register port b

; timers
timerdisable		equ	riot+0x04	; read timer disable interrupts
tim64			equ	riot+0x16	; timer : 64 disable interrupts
t1024i			equ	riot+0x1f	; timer : 1024 interrupt enable
tim64i			equ	riot+0x1e

; hardware - FDC WD 2793
status_register 	equ	wdc
command_register	equ	status_register
track_register		equ	wdc+0x01	; track register
sector_register		equ	wdc+0x02	; sector register
data_register		equ	wdc+0x03	; data register

; hardware - 1050E 
rambank_select		equ	0x0600		;xram bank select register
rombank_select		equ	0x0680		;xrom bank select register


; FDC commands
forceirq		equ	0xd0
readaddr		equ	0xc0
writetrk		equ	0xf0
readsec			equ	0x80
writesec		equ	0xa0
readtrack		equ	0xe0
writetrack		equ	0xf0
; FDC modifier bits
headload    		equ	0x08 	; head load flag
sidecomp		equ	0x02	; side compare

			opt	o- h- f-
; ZERO PAGE
			org	10

reseeks			org	*+1
verify			org	*+1
status			org	*+4
idfield			org	*+6
track			org	*+1
dir			org	*+1
stepcnt			org	*+1
steps			org	*+1
phase			org	*+1
motor_timer		org	*+2
retries			org	*+1
door_flag		org	*+1
jumper			org	*+2
pom			org	*+2
sektor			org	*+1
ztmp			org	*+3
error			org	*+1
where			org	*+2
count			org	*+1
cksum			org	*+1
reg_a			org	*+1

timer_value		org	*+1
sector_len		org	*+1
datalen			org	*+1
skew			org	*+2
preidx_l		org	*+1
preidx_h		org	*+1
gap3			org	*+1



pregap			org	*+1
idgap			org	*+1
gapbyte			org	*+1
datagap			org	*+1
sectorcount		org	*+1
mfmflag			org	*+1

turbo_flag		org	*+1
rvalue			org	*+1
src			org	*+2


modifier		equ	$200	; this must be !zp because of timings in fast sio
sekbuf			equ	$300
percom			equ	$400
cmd_frame		equ	$500


dunit			equ	cmd_frame
daux1			equ	cmd_frame+2
daux2			equ	cmd_frame+3
dcommand		equ	cmd_frame+1

			ert	* > $00ff
			org	0
