SRC:=loader.asm
BIN:=$(subst .asm,.com,$(SRC))

IMG := a.img
FLOPPY := /mnt/floppy 
FDOS := FDOS11.img


.PHONY: clean run 
generate:
		tar zxvf a.img.tar.gz 
		cp ../FDOS11.img.tar.gz .
		tar zxvf FDOS11.img.tar.gz 

run : $(BIN)
		sudo mount -o loop $(IMG) $(FLOPPY)
		sudo cp $(BIN)  $(FLOPPY)
		sudo umount $(FLOPPY)
		cp ./.dos-bochsrc  ./bochsrc
		bochs -q
run_hd:
		cp .hd-bochsrc bochsrc
		bochs -q
		
clean:
		-rm *.com *.bin
		
$(BIN) : $(SRC)
	nasm  $< -o $@
