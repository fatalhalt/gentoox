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

rc-update add dbus default
rc-update add dhcpcd default
rc-update add avahi-daemon default

sensors-detect --auto
rc-update add lm_sensors default

cp /etc/samba/smb.conf.default /etc/samba/smb.conf
sed -i "s/   workgroup = MYGROUP/   workgroup = WORKGROUP/" /etc/samba/smb.conf

# grub-mkconfig -o /boot/grub/grub.cfg




su - gentoox
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
kpackagetool5 -i "GentooX Breeze Dark Transparent.tar.gz"
