#!/bin/sh

linux_path=`realpath linux`
busybox_path=`realpath busybox`

cp busybox-config $busybox_path/.config
cd $busybox_path
make clean
CFLAGS="-I$linux_path/include" make install
