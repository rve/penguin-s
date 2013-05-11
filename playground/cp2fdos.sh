#: << 'END'
if  [ -z  "$1" ]
then
    echo "no input"
else
    sudo mount ../FDOS11.img /mnt
    sudo cp $1 /mnt/
    sudo umount /mnt
fi
#END
