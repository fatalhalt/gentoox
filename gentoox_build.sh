#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

#
# Notes: start with clean /var/db/, if you have /var/cache/distfiles/ on host only rsync that to chroot
#
# dependencies
#   base install: genkernel btrfs-progs portage-utils gentoolkit cpuid2cpuflags cryptsetup lvm2 mdadm dev-vcs/git
#
#

gitprefix="https://gitgud.io/cloveros/cloveros/raw/master"
rootpassword=gentoox
username=gentoox
userpassword=gentoox
builddate="20200101.graphite"

#build_kde=y
#clover_rice="y"
#configure_user=y
#build_iso=y


if [[ ! -f 'image/etc/gentoo-release' ]]; then
  mkdir image/
  cd image/

  cp -v /var/tmp/catalyst/builds/default/stage3-amd64-$builddate.tar.xz .

  tar xJpf /var/tmp/catalyst/builds/default/stage3-amd64-$builddate.tar.xz --xattrs --numeric-owner
  rm -f stage3*
  cp ../0001-kernel-config-cfs-r2.patch usr/src
  rsync -a ../var/ var/

  cp /etc/resolv.conf etc/
  cd ..
fi

if [[ -z $(findmnt image/proc) ]]; then
  mount -t proc none image/proc
  mount --rbind /dev image/dev
  mount --rbind /sys image/sys
else
  echo "proc already mounted..."
fi
cd image/

if [[ ! -f 'tmp/gentoox-base-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
mkdir /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
emerge-webrsync
emerge --sync
eselect profile set "default/linux/amd64/17.1"
echo 'COMMON_FLAGS="-O3 -march=sandybridge -mtune=sandybridge -mfpmath=both -pipe -funroll-loops -fgraphite-identity -floop-nest-optimize -fdevirtualize-at-ltrans -fipa-pta -fno-semantic-interposition -flto=12 -fuse-linker-plugin -malign-data=cacheline -Wl,--hash-style=gnu"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C target-cpu=native"
CPU_FLAGS_X86="aes avx mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
MAKEOPTS="-j12"
USE="-bindist"
#FEATURES="buildpkg noclean"
FEATURES="buildpkg"
ACCEPT_KEYWORDS="~amd64"
ACCEPT_LICENSE="*"
PORTAGE_NICENESS=19
GENTOO_MIRRORS="http://gentoo.ussg.indiana.edu/"
EMERGE_DEFAULT_OPTS="--jobs=4"
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"
LC_MESSAGES=C' > /etc/portage/make.conf

mkdir /etc/portage/env
echo 'CFLAGS="\${CFLAGS} -fno-lto"
CXXFLAGS="\${CFLAGS} -fno-lto"' > /etc/portage/env/nolto.conf

echo 'dev-libs/elfutils nolto.conf
dev-libs/libaio nolto.conf
media-libs/alsa-lib nolto.conf
media-libs/mesa nolto.conf
media-libs/x264 nolto.conf
dev-libs/weston nolto.conf
sys-auth/elogind nolto.conf
dev-lang/spidermonkey
x11-drivers/xf86-video-intel nolto.conf
x11-drivers/xf86-video-amdgpu nolto.conf
x11-drivers/xf86-video-ati nolto.conf
x11-drivers/xf86-video-intel nolto.conf' > /etc/portage/package.env

echo 'sys-devel/gcc graphite
sys-apps/kmod lzma
sys-kernel/linux-firmware initramfs redistributable unknown-license
x11-libs/libdrm libkms
www-client/firefox hwaccel pgo lto wayland
dev-lang/python sqlite
sys-fs/squashfs-tools zstd
sys-boot/grub:2 libzfs mount
x11-libs/libxcb xkb' > /etc/portage/package.use/gentoox

rm -rf /etc/portage/package.accept_keywords/
echo -n > /etc/portage/package.accept_keywords

emerge --autounmask=y --autounmask-write=y -vDN @world
emerge -v gentoo-sources genkernel btrfs-progs portage-utils gentoolkit cpuid2cpuflags cryptsetup lvm2 mdadm dev-vcs/git
touch /tmp/gentoox-base-done
HEREDOC
#rsync -av --delete var/cache/{binpkgs,distfiles} ../var/cache/
exit 0
else echo "base system already compiled, skipping..."; fi


if [[ ! -f 'tmp/gentoox-kernel-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
KERNELVERSION=\$(qlist -Iv gentoo-sources | tr '-' ' ' | awk '{print \$4}')
cd /usr/src/linux/

if [[ ! -f '/tmp/gentoox-kernelpatches-applied' ]]; then
  wget 'https://gitea.artixlinux.org/artixlinux/packages-kernel/raw/branch/master/linux/trunk/config' -O .config
  git clone https://github.com/graysky2/kernel_gcc_patch.git
  wget https://gitlab.com/post-factum/pf-kernel/commit/cf7a8ad26e0bd6ca8afba89f53d2e9dc43ee2598.diff -O O3-always-available.diff
  #wget --quiet -m -np -c 'ck.kolivas.org/patches/5.0/5.4/5.4-ck1/patches/'
  #wget https://gitlab.com/sirlucjan/kernel-patches/raw/master/5.4/aufs-patches/0001-aufs-20191223.patch
  wget https://raw.githubusercontent.com/sirlucjan/kernel-patches/master/5.4/aufs-patches/0001-aufs-20200113.patch
  wget https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux54-tkg/linux54-tkg-patches/0007-v5.4-fsync.patch
  wget https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux54-tkg/linux54-tkg-patches/0011-ZFS-fix.patch

  patch -p1 < kernel_gcc_patch/enable_additional_cpu_optimizations_for_gcc_v9.1+_kernel_v4.13+.patch
  patch -p1 < O3-always-available.diff
  #for f in ck.kolivas.org/patches/5.0/5.4/5.4-ck1/patches/*.patch; do patch -p1 < "\$f"; done
  patch -p0 < ../0001-kernel-config-cfs-r2.patch
  patch -p1 < 0001-aufs-20200113.patch
  echo -e "CONFIG_AUFS_FS=y\nCONFIG_AUFS_BRANCH_MAX_127=y\nCONFIG_AUFS_BRANCH_MAX_511=n\nCONFIG_AUFS_BRANCH_MAX_1023=n\nCONFIG_AUFS_BRANCH_MAX_32767=n\nCONFIG_AUFS_HNOTIFY=y\nCONFIG_AUFS_EXPORT=n\nCONFIG_AUFS_XATTR=y\nCONFIG_AUFS_FHSM=y\nCONFIG_AUFS_RDU=n\nCONFIG_AUFS_DIRREN=n\nCONFIG_AUFS_SHWH=n\nCONFIG_AUFS_BR_RAMFS=y\nCONFIG_AUFS_BR_FUSE=n\nCONFIG_AUFS_BR_HFSPLUS=n\nCONFIG_AUFS_DEBUG=n" >> .config
  sed -i "s/CONFIG_ISO9660_FS=m/CONFIG_ISO9660_FS=y/" .config
  patch -p1 < 0007-v5.4-fsync.patch
  patch -p1 < 0011-ZFS-fix.patch
  make oldconfig
  touch /tmp/gentoox-kernelpatches-applied
fi

cd ..
rm -f 0001-kernel-config-cfs-r2.patch
genkernel --kernel-config=/usr/src/linux-\$KERNELVERSION-gentoo/.config --no-mrproper --microcode --luks --lvm --mdadm --btrfs --disklabel all
XZ_OPT="--lzma1=preset=9e,dict=128MB,nice=273,depth=200,lc=4" tar --lzma -cf /usr/src/kernel-gentoox.tar.lzma /boot/*\${KERNELVERSION}* -C /lib/modules/ .

emerge -v squashfs-tools linux-firmware os-prober grub:2
touch /tmp/gentoox-kernel-done
HEREDOC
cp -v usr/src/kernel-gentoox.tar.lzma ../
exit 0
else echo "kernel already compiled, skipping..."; fi


if [[ ! -f 'tmp/gentoox-weston-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
sed -i -r "s/^USE=\"([^\"]*)\"$/USE=\"\1 elogind -consolekit -systemd udev dbus X wayland gles plymouth pulseaudio ffmpeg ipv6\"/g" /etc/portage/make.conf
FEATURES="-userpriv" emerge dev-lang/yasm  # yasm fails to build otherwise

emerge -v --autounmask=y --autounmask-write=y --keep-going=y --deep --newuse xorg-server elogind sudo vim weston wpa_supplicant nfs-utils cifs-utils dhcpcd zsh zsh-completions
#emerge -v --depclean
rc-update add dhcpcd default
touch /tmp/gentoox-weston-done
HEREDOC
exit 0
fi


if [[ ! -z $build_kde ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
eselect profile set "default/linux/amd64/17.1/desktop/plasma"
sed -i -r "s/^USE=\"([^\"]*)\"$/USE=\"\1 -webkit\"/g" /etc/portage/make.conf

mkdir -p /etc/portage/patches/media-libs/dav1d
wget https://raw.githubusercontent.com/InBetweenNames/gentooLTO/master/sys-config/ltoize/files/patches/media-libs/dav1d/dav1d-graphite-ice-workaround.patch -P /etc/portage/patches/media-libs/dav1d/

emerge layman
layman --sync-all
layman --add mv
layman --add lto-overlay
echo 'sys-config/ltoize ~amd64
app-portage/portage-bashrc-mv ~amd64
app-shells/runtitle ~amd64' >> /etc/portage/package.accept_keywords
emerge sys-config/ltoize
sed -i '1s/^/source make.conf.lto\n/' /etc/portage/make.conf
sed -i '1s/^/NTHREADS="12"\n/' /etc/portage/make.conf

emerge -v --jobs=4 --keep-going=y --autounmask=y --autounmask-write=y --deep --newuse kde-plasma/plasma-meta kde-apps/kde-apps-meta firefox mpv
cd /home/$username/
echo 'exec dbus-launch --exit-with-session startplasma-x11' > .xinitrc
chown -R $username /home/$username/
HEREDOC
exit 0
fi


if [[ ! -z $configure_user ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"

echo "root:$rootpassword" | chpasswd
useradd $username
echo "$username:$userpassword" | chpasswd
gpasswd -a $username wheel

cp /usr/share/zoneinfo/UTC /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8

echo "frozen-files=\"/etc/sudoers\"" >> /etc/dispatch-conf.conf
sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -Ei "s@c([2-6]):2345:respawn:/sbin/agetty 38400 tty@#\0@" /etc/inittab
sed -i "s@c1:12345:respawn:/sbin/agetty 38400 tty1 linux@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@" /etc/inittab
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel\nupdate_config=1" > /etc/wpa_supplicant/wpa_supplicant.conf
eselect fontconfig enable 52-infinality.conf
eselect infinality set infinality
eselect lcdfilter set infinality

usermod -aG audio,video,games,input $username
HEREDOC
exit 0
fi


if [[ ! -z $clover_rice ]]; then
cat <<HEREDOC | chroot .
cd /home/$username/
rm .bash_profile
wget $gitprefix/home/user/{.bash_profile,.zprofile,.zshrc,.fvwm2rc,.Xdefaults,.xbindkeysrc,screenfetch-dev,stats.sh,rotate_screen.sh,.emacs,.rtorrent.rc}
wget $gitprefix/home/user/.mpv/config -P .mpv/
wget $gitprefix/home/user/.config/mimeapps.list -P .config/
echo -e "[Desktop Entry]\nEncoding=UTF-8\nType=Link\nName=Home\nIcon=user-home\nExec=spacefm ~/" > Desktop/home.desktop
echo -e "[Desktop Entry]\nEncoding=UTF-8\nType=Link\nName=Applications\nIcon=folder\nExec=spacefm /usr/share/applications/" > Desktop/applications.desktop
cp /usr/share/applications/{firefox.desktop,mpv.desktop,emacs.desktop,zzz-gimp.desktop,porthole.desktop,xarchiver.desktop} Desktop/
echo -e "~rows=0\n1=home.desktop\n2=applications.desktop\n3=porthole.desktop\n4=firefox.desktop\n5=mpv.desktop\n6=emacs.desktop\n7=zzz-gimp.desktop\n8=xarchiver.desktop" > .config/spacefm/desktop0
chown -R $username /home/$username/
wget $gitprefix/livecd_install.sh -P /home/$username/
chmod +x /home/$username/livecd_install.sh
sed -i "s@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@c1:12345:respawn:/sbin/agetty -a $username --noclear 38400 tty1 linux@" /etc/inittab
sed -i "s/^/#/" /home/$username/.bash_profile
echo -e 'if [ -z "\$DISPLAY" ] && [ -z "\$SSH_CLIENT" ] && ! pgrep X > /dev/null; then
X &
export DISPLAY=:0
fvwm &
while sleep 0.2; do if [ -d /proc/\$! ]; then ((i++)); [ "\$i" -gt 6 ] && break; else i=0; fvwm & fi; done
urxvtd -o -f
urxvtc -geometry 80x24+100+100 -e sudo ./livecd_install.sh
rc-config start wpa_supplicant &> /dev/null &
nitrogen --set-zoom wallpaper.png &
spacefm --desktop &
urxvtc -geometry 1000x1+0+0 -fn 6x13 -letsp 0 -sl 0 -e ~/stats.sh
xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Tapping Enabled" 1 & xinput list --name-only | sed "/Virtual core pointer/,/Virtual core keyboard/"\!"d;//d" | xargs -I{} xinput set-prop pointer:{} "libinput Accel Profile Enabled" 0 1 &> /dev/null &
fi' >> /home/$username/.bash_profile
HEREDOC
exit 0
fi


if [[ ! -z $build_iso ]]; then
#rm -Rf /var/cache/binpkgs/* /var/cache/edb/binhost/* /etc/resolv.conf
#rm -f /tmp/*
#ToDo: clear bash history, truncate logs in /var/log/
cd ..
umount -l image/*
mv image/usr/src/kernel-gentoox.tar.lzma .
mksquashfs image/ image.squashfs -b 1M -comp xz -Xbcj x86 -Xdict-size 1M
mkdir iso/
builddate=$(wget -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/ | sed -nr "s/.*href=\"install-amd64-minimal-([0-9].*).iso\">.*/\1/p")
if [[ ! -f "current-install-amd64-minimal/install-amd64-minimal-$builddate.iso" ]]; then
  wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/install-amd64-minimal-$builddate.iso
fi
xorriso -osirrox on -indev *-$builddate.iso -extract / iso/
mv image.squashfs iso/image.squashfs
tar -xOf kernel-gentoox.tar.lzma --wildcards \*vmlinuz-\* > iso/boot/gentoo
tar -xOf kernel-gentoox.tar.lzma --wildcards \*initramfs-\* | xz -d | gzip > iso/boot/gentoo.igz
tar -xOf kernel-gentoox.tar.lzma --wildcards \*System.map-\* > iso/boot/System-gentoo.map
sed -i "s@dokeymap@aufs@g" iso/isolinux/isolinux.cfg
sed -i "s@dokeymap@aufs@g" iso/grub/grub.cfg
xorriso -as mkisofs -r -J \
	-joliet-long -l -cache-inodes \
	-isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
	-partition_offset 16 -A "Gentoo Live" \
	-b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table  \
	-o Gentoox-x86_64-$builddate.iso iso/
#rm -Rf image/ iso/ kernel-gentoox.tar.lzma
fi

