#!/bin/sh

set -ex

this_path=`realpath .`
linux_path=`realpath linux`
busybox_path=`realpath busybox`
musl_path=`realpath musl`
musl_install_dir=$this_path/build/musl

PATH=$PATH:$musl_install_dir/bin

if [ $# -eq 0 ]; then
    cd $musl_path
    ./configure --prefix=$musl_install_dir
    make -j`nproc`
    make install

    ln -sf `which ar` $musl_install_dir/bin/musl-ar
    ln -sf `which strip` $musl_install_dir/bin/musl-strip

    cp $this_path/busybox-config $busybox_path/.config
    cd $busybox_path
    CFLAGS="-I$linux_path/include" make -j`nproc` install

    cd $this_path/build/rootfs_data
    rm -rf $this_path/build/rootfs.cpio || true
    find . | cpio -o -H newc -R root:root > ../rootfs.cpio

    cp $this_path/linux-config $linux_path/.config
    cd $linux_path
    make -j`nproc`
    cp $linux_path/arch/x86_64/boot/bzImage $this_path/build/bzImage
elif [ "$1" == "run" ]; then
    qemu-system-x86_64 \
        -kernel $this_path/build/bzImage \
        --nographic \
        -append "console=ttyS0 rdinit=/bin/sh" \
        -initrd $this_path/build/rootfs.cpio \
        -m 512M
fi
