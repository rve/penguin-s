generate:
		gzip -cd a.img.gz > a.img
		gzip -cd FDOS11.img.gz > FDOS11.img
myos :
		cp .myos-bochsrc bochsrc
		#dd
		bochs -q
		
dos :
		cp .dos-bochsrc  bochsrc
		bochs -q
		
clean :
		-rm *.bin *.com
		
clean_all:
		-rm *.bin *.img


