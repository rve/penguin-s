##################################################
# Makefile
##################################################

ASM = nasm

BOOT:=boot.asm
BOOT_BIN:=$(subst .asm,.bin,$(BOOT))
objects = loader.bin kernel.bin a.bin b.bin c.bin d.bin


IMG:=a.img
FLOPPY:=/mnt/floppy/

.PHONY : run generate myos dos clean 

everything: $(objects) 

$(objects): %.bin: %.asm
	$(ASM) $< -o $@ 

$(BOOT_BIN) : $(BOOT)
	nasm $< -o $@

run : $(BOOT_BIN) $(everything)
	make everything
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	@sudo mount -o loop $(IMG) $(FLOPPY)
	@$(foreach n, $(objects), sudo cp $(n) $(FLOPPY) -v;)
	sudo umount $(FLOPPY)
	cp .myos-bochsrc  bochsrc
	bochs -q

myos :
	cp .myos-bochsrc bochsrc
	bochs -q

dos :
	cp .dos-bochsrc  bochsrc
	bochs -q

generate:
	gzip -cd a.img.gz > a.img
	gzip -cd FDOS11.img.gz > FDOS11.img

clean :
	-rm *.bin *.com

