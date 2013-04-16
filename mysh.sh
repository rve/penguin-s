nasm loader1.asm -o loader.bin
dd if=loader.bin of=a.img bs=512 
