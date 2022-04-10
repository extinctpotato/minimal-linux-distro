#!/bin/sh

this_path=`realpath .`
linux_path=`realpath linux`
busybox_path=`realpath busybox`

cp $this_path/busybox-config $busybox_path/.config
cd $busybox_path
make clean
CFLAGS="-I$linux_path/include" make -j`nproc` install

cd $this_path/build/rootfs_data
find . | cpio -o -H newc -R root:root > ../rootfs.cpio

cp $this_path/linux-config $linux_path/.config
cd $linux_path
make -j`nproc`
