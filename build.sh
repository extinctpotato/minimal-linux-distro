#!/bin/sh

set -ex

this_path=`realpath .`
linux_path=`realpath linux`
busybox_path=`realpath busybox`
musl_path=`realpath musl`
musl_install_dir=$this_path/build/musl
git_ver=`git describe --abbrev=8 --dirty --always --tags`

PATH=$PATH:$musl_install_dir/bin

if [ $# -eq 0 ]; then
    cd $musl_path
    ./configure --prefix=$musl_install_dir
    make -j`nproc`
    make install

    ln -sf `which ar` $musl_install_dir/bin/musl-ar
    ln -sf `which strip` $musl_install_dir/bin/musl-strip

    cd $linux_path
    mkdir -p $this_path/build/kernel_headers
    make headers_install ARCH=x86_64 INSTALL_HDR_PATH=$this_path/build/kernel_headers

    cp $this_path/busybox-config $busybox_path/.config
    cd $busybox_path
    make oldconfig
    CFLAGS="-I$this_path/build/kernel_headers/include" make -j`nproc` install

    musl-gcc $this_path/hello_world.c \
        -static -Os \
        -o $this_path/build/rootfs_data/bin/hello \
        -DVERSION="\"$git_ver\""

    chmod +x $this_path/build/rootfs_data/bin/hello

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
