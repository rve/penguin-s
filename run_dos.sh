: << 'END'
if  [ -z  "$1" ]
then
    #nasm loader1.asm -o loader.bin
else
    #nasm $1 -o loader.bin
fi
END
    cp dos-bochsrc  bochsrc
    #dd if=loader.bin of=a.img bs=512 conv=notrunc
    bochs -q
