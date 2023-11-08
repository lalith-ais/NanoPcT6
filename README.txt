Build U-boot :

git clone https://github.com/friendlyarm/rkbin --single-branch --depth 1 -b nanopi6
git clone https://github.com/friendlyarm/uboot-rockchip --single-branch --depth 1 -b nanopi6-v2017.09
cd uboot-rockchip/
./make.sh nanopi6

This will yield 2 files : 
uboot.img 	
rk3588_spl_loader_v1.08.111.bin (aka MiniLoaderAll.bin) 

Build Kernel :

git clone https://github.com/friendlyarm/kernel-rockchip --single-branch --depth 1 -b nanopi6-v6.1.y kernel-rockchip
cd kernel-rockchip
touch .scmversion
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 nanopi6_linux_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 nanopi6-images -j$(nproc)
mkdir -p out-modules && rm -rf out-modules/*
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 INSTALL_MOD_PATH="$PWD/out-modules" modules -j$(nproc)
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 INSTALL_MOD_PATH="$PWD/out-modules" modules_install
KERNEL_VER=$(make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 kernelrelease)
[ ! -f "$PWD/out-modules/lib/modules/${KERNEL_VER}/modules.dep" ] && depmod -b $PWD/out-modules -E Module.symvers -F System.map -w ${KERNEL_VER}
(cd $PWD/out-modules && find . -name \*.ko | xargs aarch64-linux-gnu-strip --strip-unneeded)

This creates 2 files:
kernel.img
resource.img 

The out-modules/lib shold be copied to rootfs/lib , oterwise the modules dont appear

Get build scripts :

git clone https://github.com/friendlyarm/sd-fuse_rk3588 -b kernel-6.1.y --single-branch sd-fuse_rk3588-kernel6.1
cd sd-fuse_rk3588-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3588/images-for-eflasher/ubuntu-jammy-desktop-arm64-images.tgz
tar xvzf ubuntu-jammy-desktop-arm64-images.tgz

the contents are :

ubuntu-jammy-desktop-arm64/
├── boot.img
├── dtbo.img
├── idbloader.img
├── info.conf
├── kernel.img
├── MiniLoaderAll.bin
├── misc.img
├── parameter.txt
├── resource.img
├── rootfs.img
├── uboot.img
└── userdata.img

now replate kernel.img, uboot.img MiniLoaderAll.bin with build images from kernel and uboot sources
rk3588_spl_loader_v1.08.111.bin is the MiniLoaderAll.bin

Generate rootfs.img :
Start drom debootstrap & create a rootfs. modfiy as required

copy the roorfs to sd-fuse_rk3588-kernel6.1 directory as follows :


-rwxrwxr-x  1 lalith lalith       986 Nov  3 14:35 build-boot-img.sh
-rwxrwxr-x  1 lalith lalith     13510 Nov  3 14:35 build-kernel.sh
-rwxrwxr-x  1 lalith lalith      3698 Nov  3 14:35 build-rootfs-img.sh
-rwxrwxr-x  1 lalith lalith      4979 Nov  3 14:35 build-uboot.sh
-rwxrwxr-x  1 lalith lalith        39 Nov  3 14:35 clean.sh
drwxr-xr-x  2 root   root        4096 Oct 21 10:53 eflasher
-rw-rw-r--  1 lalith lalith 301526886 Nov  6 12:34 emmc-flasher-images.tgz
drwxrwxr-x  3 lalith lalith      4096 Nov  3 14:35 files
-rwxrwxr-x  1 lalith lalith      3510 Nov  3 14:35 fusing.sh
-rwxrwxr-x  1 lalith lalith      3267 Nov  3 14:35 mk-emmc-image.sh
-rwxrwxr-x  1 lalith lalith      5614 Nov  3 14:35 mk-sd-image.sh
drwxr-xr-x  3 root   root        4096 Nov  8 13:45 out
drwxrwxr-x  4 lalith lalith      4096 Nov  5 11:54 prebuilt
-rw-rw-r--  1 lalith lalith     10238 Nov  3 14:35 README_cn.md
-rw-rw-r--  1 lalith lalith     10298 Nov  3 14:35 README.md
drwxrwxr-x  2 lalith lalith      4096 Nov  3 14:35 rkbin
drwxr-xr-x 22 root   root        4096 Nov  8 13:42 rootfs
drwxr-xr-x  2 root   root        4096 Nov  8 13:43 test
drwxrwxr-x  2 lalith lalith      4096 Nov  3 14:35 tools
drwxr-xr-x  2 lalith lalith      4096 Nov  5 11:56 ubuntu-jammy-desktop-arm64

copy the modules into rootfs/lib/
create a test dir for output
generate roofsimage by : 

./build-rootfs-img.sh rootfs/ test
this will create two files :
test
├── parameter.txt
└── rootfs.img

copy these files to ubuntu-jammy-desktop-arm64/


get eflasher:

wget http://112.124.9.243/dvdfiles/rk3588/images-for-eflasher/emmc-flasher-images.tgz
tar xvzf emmc-flasher-images.tgz

now create the sd-to-emmc flashing image

./mk-emmc-image.sh ubuntu-jammy-desktop-arm64 filename=flash-emmc.img autostart=yes

check out/ directory for the sd image which will flash emmc automatcally

reference :

https://github.com/friendlyarm/sd-fuse_rk3588/tree/kernel-6.1.y

