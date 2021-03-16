#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

set -e
echo -e 'Welcome to the GentooX setup, the installation script mainly consists of:
\t- providing this script with a target partition where system will be installed
\t- extracting precompiled squashfs system image into the specified partition
\t- setting up GRUB, BIOS or UEFI mode will be used depending how system was booted
\tGentooX uses openSUSE-style BTRFS root partition & subvolumes for snapshotting with snapper
\tGentooX requires minimum of 16GB of space, and use of BTRFS is hardcoded

Manual installation can be done via:
  mounting target partition to /mnt/install
  unsquashfs -f -i -d /mnt/install/ /mnt/cdrom/image.squashfs
  /usr/local/sbin/genfstab -U >> /mnt/install/etc/fstab
  /usr/local/sbin/arch-chroot /mnt/install/
  grub-install --target=x86_64-efi for UEFI mode or grub-install --target=i386-pc (BIOS only)
  grub-mkconfig -o /boot/grub/grub.cfg'


declare -A PART_SCHEME
PART_SCHEME[a]="Automatic"
PART_SCHEME[m]="Manual"
if [[ -d /sys/firmware/efi/ ]]; then UEFI_MODE=y; fi


setup_btrfs () {
	DEVICE=$1

	mkfs.btrfs -f -L GENTOO $DEVICE
	mkdir -p /mnt/install
	mount -o compress=lzo $DEVICE /mnt/install

	btrfs subvolume create /mnt/install/@
	btrfs subvolume create /mnt/install/@/.snapshots
	mkdir /mnt/install/@/.snapshots/1
	btrfs subvolume create /mnt/install/@/.snapshots/1/snapshot
	mkdir -p /mnt/install/@/boot/grub/
	#btrfs subvolume create /mnt/install/@/boot/grub/i386-pc
	#btrfs subvolume create /mnt/install/@/boot/grub/x86_64-efi
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
	mount -o compress=lzo $DEVICE /mnt/install

	# ls /mnt/install should respond with empty result

	mkdir /mnt/install/.snapshots
	mkdir /mnt/install/boot
	#mkdir -p /mnt/install/boot/grub/i386-pc
	#mkdir -p /mnt/install/boot/grub/x86_64-efi
	mkdir /mnt/install/home
	mkdir /mnt/install/opt
	mkdir /mnt/install/root
	mkdir /mnt/install/srv
	mkdir /mnt/install/tmp
	mkdir -p /mnt/install/usr/local
	mkdir /mnt/install/var

	mount $DEVICE /mnt/install/.snapshots -o subvol=@/.snapshots
	#mount $DEVICE /mnt/install/boot/grub/i386-pc -o subvol=@/boot/grub/i386-pc
	#mount $DEVICE /mnt/install/boot/grub/x86_64-efi -o subvol=@/boot/grub/x86_64-efi
	mount $DEVICE /mnt/install/home -o subvol=@/home
	mount $DEVICE /mnt/install/opt -o subvol=@/opt
	mount $DEVICE /mnt/install/root -o subvol=@/root
	mount $DEVICE /mnt/install/srv -o subvol=@/srv
	mount $DEVICE /mnt/install/tmp -o subvol=@/tmp
	mount $DEVICE /mnt/install/usr/local -o subvol=@/usr/local
	mount $DEVICE /mnt/install/var -o subvol=@/var
}


echo -e "\nDetected drives:\n$(lsblk | grep disk)"
while :; do
	echo
	read -erp "Automatic partitioning (a) or manual partitioning (will launch gparted)? [a/m] " -n 1 partitioning_mode
	if [[ $partitioning_mode = "a" ]]; then
        if [[ ! -z $UEFI_MODE ]]; then echo "EFI boot detected"; fi
		read -erp "Enter drive to be formatted for GentooX installation: " -i "/dev/sda" drive
        if [[ ! -z $UEFI_MODE ]]; then
          if [[ $drive =~ "nvme" ]]; then partition="${drive}p2"; else partition="${drive}2"; fi # UEFI mode
        else
          if [[ $drive =~ "nvme" ]]; then partition="${drive}p1"; else partition="${drive}1"; fi # BIOS mode
        fi
	elif [[ $partitioning_mode = "m" ]]; then
        if [[ ! -z $UEFI_MODE ]]; then echo "EFI boot detected, please also create EF00 ESP EFI partition..."; fi
		gparted &> /dev/null &
		read -erp "Enter formatted partition for GentooX installation: " -i "/dev/sda1" partition
	else
		echo "Invalid option"
		continue
	fi

	read -erp "Partitioning: ${PART_SCHEME[$partitioning_mode]}
    NOTE: in BIOS mode only 1 partition is used for whole OS including /boot,
          in UEFI 2 partitions are used, 1st is ESP EFI and 2nd is for GentooX
          (e.g. you'll see /dev/sda1 below, or /dev/sda2 or /dev/nvme0n1p2 when in UEFI mode)
    Partition: $partition  (for GentooX)
    Is this correct? [y/n] " -n 1 yn
	if [[ $yn == "y" ]]; then
		break
	fi
done


if [[ $partitioning_mode = "a" ]]; then
  if [[ ! -z $UEFI_MODE ]]; then
	echo -e "o\nY\nn\n\n\n+256M\nEF00\nn\n2\n\n\n\nw\nY\n" | gdisk $drive
    if [[ $drive =~ "nvme" ]]; then
      mkfs.vfat -F32 "${drive}p1"
      UEFI_PART="${drive}p1"
      setup_btrfs "${drive}p2"
    else
      mkfs.vfat -F32 "${drive}1"
      UEFI_PART="${drive}1"
      setup_btrfs "${drive}2"
    fi

    mkdir -p /mnt/install/boot/efi
    mount $UEFI_PART /mnt/install/boot/efi
  else
	echo -e "o\nn\np\n1\n\n\nw" | fdisk $drive # BIOS mode
    if [[ $drive =~ "nvme" ]]; then setup_btrfs "${drive}p1"; else setup_btrfs "${drive}1"; fi
  fi
else
  # user done the partitioning
  setup_btrfs $partition
  if [[ ! -z $UEFI_MODE ]]; then
    mkdir -p /mnt/install/boot/efi
    read -erp "Enter formatted EF00 ESP partition for EFI: " -i "/dev/sda1" efi_partition
    mount $efi_partition /mnt/install/boot/efi
  fi
fi

echo "extracting precompiled GentooX image.squashfs to the target partition..."
unsquashfs -f -d /mnt/install/ /mnt/cdrom/image.squashfs
/usr/local/sbin/genfstab -U /mnt/install/ >> /mnt/install/etc/fstab
echo -e "extraction complete.\n"

read -erp "set hostname: " -i "gentoox" hostname
read -erp "set domain name: " -i "haxx.dafuq" domainname
read -erp "set username: " -i "gentoox" username
read -erp "set user password: " -i "gentoox" userpassword
read -erp "set root password: " -i "gentoox" rootpassword

mount -t proc none /mnt/install/proc
mount --rbind /dev /mnt/install/dev
mount --rbind /sys /mnt/install/sys

set +e
cd /mnt/install/
cat <<HEREDOC | chroot .
source /etc/profile && export PS1="(chroot) \$PS1"
if [[ -d /sys/firmware/efi/ ]]; then UEFI_MODE=y; fi
if [[ -z $drive ]]; then drive=$(echo $partition | sed 's/[0-9]\+\$//'); fi

sensors-detect --auto
rc-update add lm_sensors default
rc-update add syslog-ng default

HWTHREADS=\$(getconf _NPROCESSORS_ONLN)
sed -i -r "s/^MAKEOPTS=\"([^\"]*)\"$/MAKEOPTS=\"-j\$HWTHREADS\"/g" /etc/portage/make.conf
sed -i -r "s/^NTHREADS=\"([^\"]*)\"$/NTHREADS=\"\$HWTHREADS\"/g" /etc/portage/make.conf
sed -i "s/-flto=8/-flto=\$HWTHREADS/" /etc/portage/make.conf
#rc-update add zfs-import boot
#rc-update add zfs-mount boot
rc-update delete virtualbox-guest-additions default
rm -f /etc/xdg/autostart/vboxclient.desktop
rm -f /usr/share/applications/avidemux-2.7.desktop

sed -i "s/gentoox/$hostname/g" /etc/conf.d/hostname
sed -i "s/gentoox/$hostname/g" /etc/hosts
sed -i "s/haxx.dafuq/$domainname/g" /etc/hosts
sed -i "s/haxx.dafuq/$domainname/g" /etc/conf.d/net

echo '#!/bin/bash
#echo 0f > /sys/kernel/debug/dri/0/pstate
cpupower frequency-set -g performance' > /etc/local.d/my.start
chmod +x /etc/local.d/my.start

touch /swapfile
chattr +C /swapfile
dd if=/dev/zero of=/swapfile count=512 bs=1MiB
chmod 600 /swapfile
mkswap -L MYSWAP /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo 'vm.swappiness=10' >> /etc/sysctl.d/local.conf

yes $rootpassword | passwd root
if [[ $username != "gentoox" ]]; then
  usermod --login $username --move-home --home /home/$username gentoox
  groupmod --new-name $username gentoox
fi
yes $userpassword | passwd $username

if [[ ! -z "$UEFI_MODE" ]]; then
  grub-install --target=x86_64-efi
else
  grub-install --target=i386-pc $drive
fi
grub-mkconfig -o /boot/grub/grub.cfg

#emerge --sync
HEREDOC

sync
umount -l /mnt/install/boot/efi /mnt/install/var /mnt/install/usr/local /mnt/install/tmp /mnt/install/srv /mnt/install/root /mnt/install/opt /mnt/install/home /mnt/install/boot/grub/x86_64-efi /mnt/install/boot/grub/i386-pc /mnt/install/.snapshots /mnt/install 1>/dev/null 2>&1
sync
echo "Installation complete, you may remove the install media and reboot"
