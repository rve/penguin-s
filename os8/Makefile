SRC:=ms3.asm
BIN:=$(subst .asm,.com,$(SRC))

run:
		sudo mount ../FDOS11.img /mnt
		sudo cp $(BIN)  /mnt/
		sudo umount /mnt
