#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# post install
#
# adjust nproc in make.conf

# setup /etc/fstab

#plymouth-set-default-theme fade-in
# adjust /etc/default/grub
#   splash quiet

#rc-update add zfs-import boot
#rc-update add zfs-mount boot


sensors-detect --auto
rc-update add lm_sensors default

# grub-install
# grub-mkconfig -o /boot/grub/grub.cfg



setup_btrfs () {
	DEVICE=$1

	mkfs.btrfs -f -L GENTOO /dev/$DEVICE
	mkdir /mnt/install
	mount /dev/$DEVICE /mnt/install

	btrfs subvolume create /mnt/install/@
	btrfs subvolume create /mnt/install/@/.snapshots
	mkdir /mnt/install/@/.snapshots/1
	btrfs subvolume create /mnt/install/@/.snapshots/1/snapshot
	mkdir -p /mnt/install/@/boot/grub2/
	btrfs subvolume create /mnt/install/@/boot/grub/i386-pc
	btrfs subvolume create /mnt/install/@/boot/grub/x86_64-efi
	btrfs subvolume create /mnt/install/@/home
	btrfs subvolume create /mnt/install/@/opt
	btrfs subvolume create /mnt/install/@/root
	btrfs subvolume create /mnt/install/@/srv
	btrfs subvolume create /mnt/install/@/tmp
	mkdir /mnt/install/@/usr/
	btrfs subvolume create /mnt/install/@/usr/local
	btrfs subvolume create /mnt/install/@/var

	chattr +C /mnt/install/@/var

	echo "<?xml version=\"1.0\"?>
	<snapshot>
	  <type>single</type>
	  <num>1</num>
	  <date>$(date)</date>
	  <description>first root filesystem</description>
	</snapshot>" > /mnt/install/@/.snapshots/1/info.xml

	btrfs subvolume set-default $(btrfs subvolume list /mnt/install | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+') /mnt/install
	umount /mnt/install
	mount /dev/$DEVICE /mnt/install

	# ls /mnt/install should respond with empty result

	mkdir /mnt/install/.snapshots
	mkdir -p /mnt/install/boot/grub/i386-pc
	mkdir -p /mnt/install/boot/grub/x86_64-efi
	mkdir /mnt/install/home
	mkdir /mnt/install/opt
	mkdir /mnt/install/root
	mkdir /mnt/install/srv
	mkdir /mnt/install/tmp
	mkdir -p /mnt/install/usr/local
	mkdir /mnt/install/var

	mount /dev/$DEVICE /mnt/install/.snapshots -o subvol=@/.snapshots
	mount /dev/$DEVICE /mnt/install/boot/grub/i386-pc -o subvol=@/boot/grub/i386-pc
	mount /dev/$DEVICE /mnt/install/boot/grub/x86_64-efi -o subvol=@/boot/grub/x86_64-efi
	mount /dev/$DEVICE /mnt/install/home -o subvol=@/home
	mount /dev/$DEVICE /mnt/install/opt -o subvol=@/opt
	mount /dev/$DEVICE /mnt/install/root -o subvol=@/root
	mount /dev/$DEVICE /mnt/install/srv -o subvol=@/srv
	mount /dev/$DEVICE /mnt/install/tmp -o subvol=@/tmp
	mount /dev/$DEVICE /mnt/install/usr/local -o subvol=@/usr/local
	mount /dev/$DEVICE /mnt/install/var -o subvol=@/var

	umount -l /mnt/install/boot/efi /mnt/install/var /mnt/install/usr/local /mnt/install/tmp /mnt/install/srv /mnt/install/root /mnt/install/opt /mnt/install/home \
	          /mnt/install/boot/grub/x86_64-efi /mnt/install/boot/grub/i386-pc /mnt/install/.snapshots /mnt/install
}

