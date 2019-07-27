;	  _  ___  ____   ___       
;	 / |/ _ \| ___| / _ \  ___ 
;	 | | | | |___ \| | | |/ _ \
;	 | | |_| |___) | |_| |  __/
;	 |_|\___/|____/ \___/ \___|
;                          
; 1050E Hardware by Sebastian Bartkowicz (Candle) - http://spiflash.org
; 1050E firmware by Michal Szwaczko (Mikey) - http://m.wirelabs.net
;
; Firmware Copyright (c) 2010-2012,2013,2019 Michal Szwaczko
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

; hardware 
riot			equ	0x700		; riot base address
wdc			equ	0x780		; wdc controller base address

; RIOT
porta			equ	riot		; data register port a
pactl			equ	riot+0x01	; data direction register port a
portb			equ	riot+0x02	; data register port b
pbctl			equ	riot+0x03	; data direction register port b
timerdisable		equ	riot+0x04	; read timer disable interrupts
tim64			equ	riot+0x16	; timer : 64 disable interrupts
t1024i			equ	riot+0x1f	; timer : 1024 interrupt enable
tim64i			equ	riot+0x1e

; WD 2793
status_register 	equ	wdc
command_register	equ	status_register
track_register		equ	wdc+0x01	; track register
sector_register		equ	wdc+0x02	; sector register
data_register		equ	wdc+0x03	; data register

; 1050E 
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
reseeks			equ 	0x0a	
verify			equ 	0x0b	
status			equ 	0x0c 	;4b
idfield			equ 	0x10	;6b
track			equ 	0x16	
dir			equ 	0x17	
stepcnt			equ 	0x18	
steps			equ 	0x19	
phase			equ 	0x1a	
motor_timer		equ 	0x1b	;2b
retries			equ 	0x1d	
door_flag		equ 	0x1e	
jumper			equ 	0x1f	;2b
pom			equ 	0x21	;2b
sektor			equ 	0x23	
ztmp			equ 	0x24	;3b
error			equ 	0x27	
where			equ 	0x28	;2b
count			equ 	0x2a	
cksum			equ 	0x2b	
reg_a			equ 	0x2c	

timer_value		equ 	0x2d	
sector_len		equ 	0x2e	
datalen			equ 	0x2f	
skew			equ 	0x30	;2b
preidx_l		equ 	0x32	
preidx_h		equ 	0x33	

gap3			equ 	0x34	
pregap			equ 	0x35	
idgap			equ 	0x36	
gapbyte			equ 	0x37	
datagap			equ 	0x38	

sectorcount		equ 	0x39	
mfmflag			equ 	0x3a	

turbo_flag		equ 	0x3b	
rvalue			equ 	0x3c	
src			equ 	0x3d	;2b


modifier		equ	$200	; this must be !zp because of timings in fast sio
sekbuf			equ	$300
percom			equ	$400
cmd_frame		equ	$500


dunit			equ	cmd_frame
daux1			equ	cmd_frame+2
daux2			equ	cmd_frame+3
dcommand		equ	cmd_frame+1

			ert	* > $00ff
