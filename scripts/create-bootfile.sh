#!/bin/bash
BOOTDIR=/boot
EFIDIR=$BOOTDIR/EFI
LINUXDIR=$EFIDIR/Linux
KERNEL_SUFFIX=linux-lts
SECURE_BOOT_KEYS=/etc/secure-boot
#setup ucode
CPUINFO=$(cat /proc/cpuinfo  | rg -e vendor_id ) #| rg -i intel | wc -l

if [  $(echo $CPUINFO | rg -i intel | wc -l) -ne 0 ] && [ -e $BOOTDIR/intel-ucode.img ]; then
	UCODE=$BOOTDIR/intel-ucode.img	
elif [ $(echo $CPUINFO | rg -i amd | wc -l) -ne 0 ] && [ -e $BOOTDIR/amd-ucode.img ]; then
	UCODE=$BOOTDIR/amd-ucode.img	
else 
	UCODE=	
fi

echo $UCODE

#backup old copy
if [[ -e $LINUXDIR/$KERNEL_SUFFIX.efi ]]; then
	mv $LINUXDIR/$KERNEL_SUFFIX{,-backup}.efi
fi
if [[ -e $LINUXDIR/$KERNEL_SUFFIX-fallback.efi ]]; then
	mv $LINUXDIR/$KERNEL_SUFFIX-fallback{,-backup}.efi
fi

function combineUcode(){
	cat $UCODE > $BOOTDIR/tmpramfs.img
	cat $BOOTDIR/initramfs-$KERNEL_SUFFIX$1.img >> $BOOTDIR/tmpramfs.img
}

function createEFI(){
	combineUcode $1
	objcopy \
	    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="/root/command-line.txt" --change-section-vma .cmdline=0x30000 \
	    --add-section .linux="$BOOTDIR/vmlinuz-$KERNEL_SUFFIX" --change-section-vma .linux=0x2000000 \
	    --add-section .initrd="$BOOTDIR/tmpramfs.img" --change-section-vma .initrd=0x3000000 \
 	   "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "$LINUXDIR/$KERNEL_SUFFIX$1.efi"
	sbsign --key $SECURE_BOOT_KEYS/db.key --cert $SECURE_BOOT_KEYS/db.crt --out $LINUXDIR/$KERNEL_SUFFIX$1.efi{,}
}

#	    --add-section .splash="/usr/share/systemd/bootctl/splash-arch.bmp" --change-section-vma .splash=0x40000 \
createEFI 
createEFI -fallback 

