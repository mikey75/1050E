MADS=mads -l -u -t
DEBUGFLAGS=Z

all: clean main.o flasher.o 

FILES=  main.asm  \
	time.asm \
	serial.asm \
	motor.asm \
	id_disk.asm \
#	debug.asm \
	fallback.asm \
	wormfood.asm \
	macros.asm \
	sector.asm \
	status.asm  \
	flasher/flasher.asm \
	serial-fast.asm
	
main.o:	$(FILES)
	@$(MADS) $< -o:main.o  -d:$(DEBUGFLAGS) 

flasher.o: flasher.asm 
	@$(MADS) $< -o:flasher.o  -d:$(DEBUGFLAGS)

#romdiskflasher.o: flasher/romdiskflasher.asm
#	$(MADS) $< -o:$@  -d:$(DEBUGFLAGS)
#
#testsio: pc-tools/readserial.c
#	$(CC) -O2 $< -o testserial
	
siomon: siomon.c 
	@$(CC)  -O2 $< -o siomon

sioflash: sioflash.c 
	@$(CC)  -O2 $< -o sioflash

#fallbackflash: pc-tools/fallbackflash.c
#	$(CC) -O2 $< -ofalbackflash
#tags:#
#	ctags $(SRCS)
#
clean:
	@rm -f *.o *.inc *.xex *.lst *.lab *.obx siomon sioflash tags *.bin a.out testserial
	@rm -f obj/*.o

flash:
	sudo ./epsiflash-cli burn obj/main.o

burn: all
	sudo ./sioflash main.o flasher.o

compare:
	@cmp -l main.o orig/1050E.bin >/dev/null || echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!! NOT SAME !!!!!!!!!!!!!!"
