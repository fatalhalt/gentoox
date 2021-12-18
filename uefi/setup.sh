#!/bin/sh
kver=$(uname -r)
esp=$(lsblk -no pkname $(findmnt --noheadings -o source /boot/efi))

cp /usr/share/shim/* /boot/efi/EFI/gentoo/
mv /boot/efi/EFI/gentoo/BOOTX64.EFI /boot/efi/EFI/gentoo/shimx64.efi
ln -sf /usr/src/linux/scripts/sign-file /usr/src/uefi/
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=GENTOOX/"
openssl x509 -in MOK.der -inform DER -outform PEM -out MOK.pem
mokutil --import MOK.der

grub-install --target=x86_64-efi --efi-directory=/boot/efi --modules="tpm" --no-nvram
sbsign --key MOK.priv --cert MOK.pem /boot/efi/EFI/gentoo/grubx64.efi --output grubx64.efi.signed
sbsign --key MOK.priv --cert MOK.pem /boot/vmlinuz-${kver} --output vmlinuz-${kver}.signed
mv grubx64.efi.signed /boot/efi/EFI/gentoo/grubx64.efi
mv vmlinuz-${kver}.signed /boot/vmlinuz-${kver}
cp -r /lib/modules/$kver/kernel/ kernel
./mod-sign.sh MOK.priv MOK.der ./kernel/
cp -r ./kernel/ /lib/modules/$kver/
rm -rf kernel

genkernel --kernel-config=/usr/src/linux/.config --compress-initramfs-type=zstd --microcode --luks --lvm --mdadm --btrfs --zfs initramfs
efibootmgr -B -b $(efibootmgr | grep gentoo | cut -c 5-8)
efibootmgr -c -d $esp -p 1 -L "GentooX" -l "\EFI\gentoo\shimx64.efi" 
