SRC:=kernel.asm
BIN:=$(subst .asm,.com,$(SRC))

IMG := a.img
FLOPPY := /mnt/floppy 
FDOS := FDOS11.img


.PHONY: everything clean run 
generate:
		tar zxvf a.img.tar.gz 
		cp ../FDOS11.img.tar.gz .
		tar zxvf FDOS11.img.tar.gz 

everything : $(BIN)
		sudo mount -o loop $(IMG) $(FLOPPY)
		sudo cp $(BIN)  $(FLOPPY)
		sudo umount $(FLOPPY)
		cp ./.dos-bochsrc  ./bochsrc
		bochs -q
clean:
		-rm *.com *.bin
		
$(BIN) : $(SRC)
	nasm  $< -o $@
