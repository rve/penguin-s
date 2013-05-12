myos :
		gzip -cd a.img.gz > a.img
		cp myos-bochsrc bochsrc
		#dd
		bochs -q
dos :
		gzip -cd FDOS11.img.gz > FDOS11.img
		cp dos-bochsrc  bochsrc
		bochs -q
clean :
		-rm *.bin
		
clean_all:
		-rm *.bin *.img


