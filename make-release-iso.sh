#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi


builddate="$(date +%Y%m%d).graphite"
builddir="build-$(date +%Y%m%d)"

cd $builddir

if [[ -z $(findmnt image/proc) ]]; then
  mount -t proc none image/proc
  mount --rbind /dev image/dev
  mount --rbind /sys image/sys
else
  echo "proc already mounted..."
fi
cd image/

cat <<HEREDOC | chroot .
  eclean-dist --deep
  eclean-pkg --deep
  rm -rf /var/tmp/portage/*
  rm -f /usr/src/linux/.tmp*
  find /usr/src/linux/ -name "*.o" -exec rm -f {} \;
  find /usr/src/linux/ -name "*.ko" -exec rm -f {} \;
  rm -f /var/tmp/genkernel/*
  rm -f /var/cache/eix/portage.eix
  rm -f /var/cache/edb/mtimedb
  rm -rf /var/db/repos/gentoo/*
  rm -rf /var/db/repos/gentoo/.*
  truncate -s 0 /var/log/*.log
  truncate -s 0 /var/log/portage/elog/summary.log
  rm -f /var/log/genkernel.log
  history -c
  history -w
HEREDOC
cd ..

umount -l image/var/cache/{binpkgs,distfiles}
umount -l image/*

mksquashfs image/ image.squashfs -b 1M -comp zstd -Xcompression-level 20
mv image.squashfs iso/image.squashfs

xorriso -as mkisofs -iso-level 3 -r -J \
	-joliet-long -l -cache-inodes \
	-isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
	-partition_offset 16 -A "GENTOOX" \
	-b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e gentoo.efimg -no-emul-boot -isohybrid-gpt-basdat \
    -V "GENTOOX" -o GentooX-x86_64-$builddate.iso iso/

