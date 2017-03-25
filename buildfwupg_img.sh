#!/bin/sh
linux=linux-custom
linux=$(sed  -n  -e 's|/|_|g' -e 's|BR2_LINUX_KERNEL_CUSTOM_GIT_VERSION=\"\(.*\)\"|\1|gp' < .config)
linux=linux-$linux

make
rm -Rf output/build/busybox-1.21.0/
sleep 3
make
sleep 5
mkdir -p outputFWupg
cp -a fwconfigs/FWupg/FWupg.config outputFWupg/.config
make O=./outputFWupg
sleep 2
cp -a outputFWupg/build/${linux}/arch/arm/configs/am335x_fwupdate_defconfig outputFWupg/build/${linux}/.config
sleep 2
cp -af primax_packages/bootloader/MLO outputFWupg/target/media/sda1/update/MLO
cp -af primax_packages/bootloader/u-boot.img outputFWupg/target/media/sda1/update/u-boot.img
md5sum outputFWupg/target/media/sda1/update/MLO | cut -c 1-32 > outputFWupg/target/media/sda1/update/MLO.md5
md5sum outputFWupg/target/media/sda1/update//u-boot.img  | cut -c 1-32 > outputFWupg/target/media/sda1/update/u-boot.img.md5
make O=./outputFWupg
FW_Version=`cat output/target/etc/version`
rm -f MyPassportWireless_$FW_Version.bin
#cp -af primax_packages/bootloader/MLO output/images/MLO
#cp -af primax_packages/bootloader/u-boot.img output/images/u-boot.img
mkdir -p fwupg_images
cd fwupg_images
echo "AV1W" > package
cp ../fwupg_patch/upgrade.sh .
md5sum ../fwupg_patch/upgrade.sh | cut -c 1-32 > upgrade.sh.md5
#cp ../output/images/MLO .
#md5sum ../output/images/MLO | cut -c 1-32 > MLO.md5
#cp ../output/images/u-boot.img .
#md5sum ../output/images/u-boot.img | cut -c 1-32 > u-boot.img.md5
cp ../output/images/uImage .
md5sum ../output/images/uImage | cut -c 1-32 > uImage.md5
cp ../output/images/AsmSataFw.bin .
md5sum ../output/images/AsmSataFw.bin | cut -c 1-32 > AsmSataFw.bin.md5
cp ../outputFWupg/images/rootfs.cpio .
md5sum ../outputFWupg/images/rootfs.cpio | cut -c 1-32 > rootfs.cpio.md5
cp ../outputFWupg/images/uImage uImage-update
md5sum ../outputFWupg/images/uImage | cut -c 1-32 > uImage-update.md5
cp ../output/target/etc/version .
md5sum ../output/target/etc/version | cut -c 1-32 > version.md5
cp ../output/target/etc/version.packages .
md5sum ../output/target/etc/version.packages | cut -c 1-32 > version.packages.md5
cp ../output/target/etc/version.buildtime .
md5sum ../output/target/etc/version.buildtime | cut -c 1-32 > version.buildtime.md5
md5sum * > checklist
cd ..
tar cvfz "MyPassportWireless_$FW_Version.bin" fwupg_images/
rm -Rf fwupg_images/
md5sum "MyPassportWireless_$FW_Version.bin"
