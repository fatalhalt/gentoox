#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

#
# Notes
# • start with clean /var/db/, if you have binpkgs or distfiles on a host you can mount --bind or rsync them to the chroot
# • plymouth graphical splash via genkernel-next is commented out as it only supports systemd, GentooX is using OpenRC
# • ZFS temporarily disabled as it's not officially supported in Linux 5.5 and also errors with:
#     FATAL: modpost: GPL-incompatible module zfs.ko uses GPL-only symbol '__rcu_read_lock'
#
# dependencies
#   base install: genkernel btrfs-progs portage-utils gentoolkit cpuid2cpuflags cryptsetup lvm2 mdadm dev-vcs/git
#
#

gitprefix="https://gitgud.io/cloveros/cloveros/raw/master"
rootpassword=live
username=gentoox
userpassword=live
#builddate="$(date +%Y%m%d).graphite"
builddate="20200127.graphite"
#builddir="build-$(date +%Y%m%d)"
builddir="build-20200127"
KERNEL_CONFIG_DIFF="0001-kernel-config-cfs-r2.patch"

binpkgs=/root/var/cache/binpkgs/
distfiles=/root/var/cache/distfiles/

#build_weston=y
#build_kde=y
#build_steam=y
#build_extra=y
#configure_user=y
#clover_rice="y"
#build_iso=y


if [[ ! -d $builddir ]]; then mkdir -v $builddir; fi
cd $builddir

if [[ ! -f 'image/etc/gentoo-release' ]]; then
  mkdir image/
  cd image/

  cp -v /var/tmp/catalyst/builds/default/stage3-amd64-$builddate.tar.xz .
  if [[ $? -ne 0 ]]; then exit 1; fi

  echo 'extracting stage3 tarball...'
  tar xJpf /var/tmp/catalyst/builds/default/stage3-amd64-$builddate.tar.xz --xattrs --numeric-owner
  rm -f stage3*

  cp ../../$KERNEL_CONFIG_DIFF usr/src
  mkdir -p etc/portage/patches
  cp -r ../../patches/* etc/portage/patches/
  mkdir -p etc/portage/patches/app-crypt/efitools
  cp ../../efitools-1.9.2-fixup-UNKNOWN_GLYPH.patch etc/portage/patches/app-crypt/efitools/
  cp ../../arch-chroot usr/local/sbin/
  cp ../../genfstab usr/local/sbin/

  if [[ ! -z $binpkgs ]] && [[ ! -z $distfiles ]]; then
    #rsync -a $binpkgs var/cache/binpkgs/
    #rsync -a $distfiles var/cache/distfiles/
    mount --bind $binpkgs var/cache/binpkgs/
    mount --bind $distfiles var/cache/distfiles/
  fi

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
echo 'CFLAGS="-O2 -march=sandybridge -mtune=sandybridge -pipe"
CXXFLAGS="\${CFLAGS}"' > /etc/portage/env/O2nolto.conf

echo 'dev-libs/elfutils nolto.conf
app-crypt/efitools nolto.conf
dev-libs/libaio nolto.conf
media-libs/alsa-lib nolto.conf
media-libs/mesa nolto.conf
media-libs/x264 nolto.conf
dev-libs/weston nolto.conf
sys-auth/elogind nolto.conf
dev-lang/spidermonkey nolto.conf
sys-devel/llvm nolto.conf
sys-libs/compiler-rt-sanitizers nolto.conf
x11-drivers/xf86-video-intel nolto.conf
x11-drivers/xf86-video-amdgpu nolto.conf
x11-drivers/xf86-video-ati nolto.conf
x11-drivers/xf86-video-intel nolto.conf
x11-base/xorg-server nolto.conf
dev-libs/weston nolto.conf
dev-util/umockdev O2nolto.conf' > /etc/portage/package.env

echo 'sys-devel/gcc graphite
sys-apps/kmod lzma
sys-kernel/linux-firmware initramfs redistributable unknown-license
x11-libs/libdrm libkms
media-libs/mesa d3d9 lm-sensors opencl -vaapi vdpau vulkan vulkan-overlay xa xvmc
www-client/firefox -system-libvpx hwaccel pgo lto wayland
dev-libs/boost python
dev-lang/python sqlite
sys-fs/squashfs-tools zstd
sys-boot/grub:2 mount # libzfs
x11-libs/libxcb xkb
dev-db/sqlite secure-delete
x11-base/xorg-server xvfb
sys-apps/xdg-desktop-portal screencast
dev-vcs/git tk' > /etc/portage/package.use/gentoox

rm -rf /etc/portage/package.accept_keywords/
echo -n > /etc/portage/package.accept_keywords

emerge --autounmask=y --autounmask-write=y -vDN @world
emerge -v gentoo-sources genkernel portage-utils gentoolkit cpuid2cpuflags cryptsetup lvm2 mdadm dev-vcs/git btrfs-progs app-arch/lz4 ntfs3g dosfstools exfat-utils gptfdisk efitools shim
touch /tmp/gentoox-base-done
HEREDOC
#rsync -av --delete var/cache/{binpkgs,distfiles} ../var/cache/
exit 0
else echo "base system already compiled, skipping..."; fi


if [[ ! -f 'tmp/gentoox-kernel-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
KERNELVERSION=\$(qlist -Iv gentoo-sources | tr '-' ' ' | awk '{print \$4}')

#echo -e '\nPLYMOUTH="yes"
#PLYMOUTH_THEME="fade-in"' >> /etc/genkernel.conf
#echo -e '\nrc_interactive="NO"' >> /etc/rc.conf
cd /usr/src/linux/

if [[ ! -f '/tmp/gentoox-kernelpatches-applied' ]]; then
  wget --quiet 'https://gitea.artixlinux.org/artixlinux/packages-kernel/raw/branch/master/linux/trunk/config' -O .config
  git clone https://github.com/graysky2/kernel_gcc_patch.git
  wget --quiet https://gitlab.com/post-factum/pf-kernel/commit/cf7a8ad26e0bd6ca8afba89f53d2e9dc43ee2598.diff -O O3-always-available.diff
  #wget --quiet -m -np -c 'ck.kolivas.org/patches/5.0/5.5/5.5-ck1/patches/'
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/raw/master/5.5/aufs-patches/0001-aufs-20200127.patch
  wget --quiet https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux55-tkg/linux55-tkg-patches/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch
  wget --quiet https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux55-tkg/linux55-tkg-patches/0002-clear-patches.patch
  wget --quiet https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux55-tkg/linux55-tkg-patches/0006-add-acs-overrides_iommu.patch
  wget --quiet https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux55-tkg/linux55-tkg-patches/0007-v5.5-fsync.patch
  wget --quiet https://git.froggi.es/tkg/PKGBUILDS/raw/master/linux55-tkg/linux55-tkg-patches/0011-ZFS-fix.patch

  patch -p1 < kernel_gcc_patch/enable_additional_cpu_optimizations_for_gcc_v9.1+_kernel_v5.5+.patch
  patch -p1 < O3-always-available.diff
  #for f in ck.kolivas.org/patches/5.0/5.5/5.5-ck1/patches/*.patch; do patch -p1 < "\$f"; done
  patch -p0 < ../$KERNEL_CONFIG_DIFF
  patch -p1 < 0001-aufs-20200127.patch
  echo -e "CONFIG_AUFS_FS=y\nCONFIG_AUFS_BRANCH_MAX_127=y\nCONFIG_AUFS_BRANCH_MAX_511=n\nCONFIG_AUFS_BRANCH_MAX_1023=n\nCONFIG_AUFS_BRANCH_MAX_32767=n\nCONFIG_AUFS_HNOTIFY=y\nCONFIG_AUFS_EXPORT=n\nCONFIG_AUFS_XATTR=y\nCONFIG_AUFS_FHSM=y\nCONFIG_AUFS_RDU=n\nCONFIG_AUFS_DIRREN=n\nCONFIG_AUFS_SHWH=n\nCONFIG_AUFS_BR_RAMFS=y\nCONFIG_AUFS_BR_FUSE=n\nCONFIG_AUFS_BR_HFSPLUS=n\nCONFIG_AUFS_DEBUG=n" >> .config
  sed -i "s/CONFIG_ISO9660_FS=m/CONFIG_ISO9660_FS=y/" .config
  patch -p1 < 0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch
  patch -p1 < 0002-clear-patches.patch
  patch -p1 < 0006-add-acs-overrides_iommu.patch
  patch -p1 < 0007-v5.5-fsync.patch
  patch -p1 < 0011-ZFS-fix.patch
  sed -i 's/CONFIG_DEFAULT_HOSTNAME="artixlinux"/CONFIG_DEFAULT_HOSTNAME="gentoox"/' .config
  make oldconfig
  touch /tmp/gentoox-kernelpatches-applied
fi

cd /usr/src
rm -f $KERNEL_CONFIG_DIFF
#mkdir -p /usr/share/genkernel/distfiles/
#wget https://www.busybox.net/downloads/busybox-1.20.2.tar.bz2 -d /usr/share/genkernel/distfiles/
#cho -e '\nMAKEOPTS="-j12"' >> /etc/genkernel.conf

# former command is genkernel-next (systemd only), latter is for genkernel
#genkernel --kernel-config=/usr/src/linux-\$KERNELVERSION-gentoo/.config --no-mrproper --udev --plymouth --luks --lvm --mdadm --btrfs --zfs all
genkernel --kernel-config=/usr/src/linux-\$KERNELVERSION-gentoo/.config --no-mrproper kernel

#unmask zfs to prompt installation of masked zfs-9999 zfs-kmod-9999
#echo 'sys-fs/zfs
#sys-fs/zfs-kmod' >> /etc/portage/package.unmask
#echo 'sys-fs/zfs **
#sys-fs/zfs-kmod **' >> /etc/portage/package.accept_keywords
emerge -v squashfs-tools linux-firmware os-prober # zfs zfs-kmod

genkernel --microcode --luks --lvm --mdadm --btrfs --disklabel initramfs # --zfs
XZ_OPT="--lzma1=preset=9e,dict=128MB,nice=273,depth=200,lc=4" tar --lzma -cf /usr/src/kernel-gentoox.tar.lzma /boot/*\${KERNELVERSION}* -C /lib/modules/ .

emerge -v grub:2
sed -i "s/#GRUB_CMDLINE_LINUX_DEFAULT=\"\"/GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=z3fold\"/" /etc/default/grub
sed -i "s/#GRUB_GFXMODE=640x480/GRUB_GFXMODE=auto/" /etc/default/grub
sed -i "s/#GRUB_GFXPAYLOAD_LINUX=/GRUB_GFXPAYLOAD_LINUX=keep/" /etc/default/grub
#rc-update add zfs-import boot
#rc-update add zfs-mount boot
touch /tmp/gentoox-kernel-done
HEREDOC
cp -v usr/src/kernel-gentoox.tar.lzma ../
exit 0
else echo "kernel already compiled, skipping..."; fi


if [[ ! -z $build_weston ]] && [[ ! -f 'tmp/gentoox-weston-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
sed -i -r "s/^USE=\"([^\"]*)\"$/USE=\"\1 elogind -consolekit -systemd udev dbus X wayland gles vulkan plymouth pulseaudio ffmpeg ipv6\"/g" /etc/portage/make.conf
FEATURES="-userpriv" emerge dev-lang/yasm  # yasm fails to build otherwise

#echo 'sys-kernel/genkernel-next plymouth
#sys-boot/plymouth gdm' > /etc/portage/package.use/gentoox

echo -e '\ndev-ruby/minitest ruby_targets_ruby27
dev-ruby/net-telnet ruby_targets_ruby27
dev-ruby/power_assert ruby_targets_ruby27
dev-ruby/rake ruby_targets_ruby27
dev-ruby/test-unit ruby_targets_ruby27
dev-ruby/xmlrpc ruby_targets_ruby27
dev-ruby/bundler ruby_targets_ruby27
dev-ruby/did_you_mean ruby_targets_ruby27
dev-ruby/json ruby_targets_ruby27
dev-ruby/rdoc ruby_targets_ruby27
virtual/rubygems ruby_targets_ruby27
dev-ruby/rubygems ruby_targets_ruby27
dev-ruby/kpeg ruby_targets_ruby27
dev-ruby/racc ruby_targets_ruby27' >> /etc/portage/package.use/gentoox

emerge -v --autounmask=y --autounmask-write=y --keep-going=y --deep --newuse xorg-server elogind sudo vim weston wpa_supplicant snapper \
nfs-utils cifs-utils samba dhcpcd nss-mdns zsh zsh-completions powertop lm-sensors screenfetch #plymouth-openrc-plugin
#emerge -v --depclean
touch /tmp/gentoox-weston-done
HEREDOC
exit 0
fi


if [[ ! -z $build_kde ]] && [[ ! -f 'tmp/gentoox-kde-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
eselect profile set "default/linux/amd64/17.1/desktop/plasma"
sed -i -r "s/^USE=\"([^\"]*)\"$/USE=\"\1 -webkit\"/g" /etc/portage/make.conf

emerge layman
layman --sync-all
yes | layman --add mv
yes | layman --add lto-overlay
echo 'sys-config/ltoize ~amd64
app-portage/portage-bashrc-mv ~amd64
app-shells/runtitle ~amd64' >> /etc/portage/package.accept_keywords
emerge sys-config/ltoize
sed -i '1s/^/source make.conf.lto\n/' /etc/portage/make.conf
sed -i '1s/^/NTHREADS="12"\n/' /etc/portage/make.conf

echo -e '\nkde-plasma/plasma-meta discover networkmanager thunderbolt
kde-apps/kio-extras samba' >> /etc/portage/package.use/gentoox
emerge -v --jobs=4 --keep-going=y --autounmask=y --autounmask-write=y --deep --newuse kde-plasma/plasma-meta kde-apps/kde-apps-meta kde-apps/kmail latte-dock calamares gparted plasma-sdk gdb dos2unix qt-creator firefox mpv app-misc/screen audacious-plugins audacious net-irc/hexchat

yes | layman -o https://raw.githubusercontent.com/fosero/flatpak-overlay/master/repositories.xml -f -a flatpak-overlay -q
emerge -v sys-apps/flatpak

touch /tmp/gentoox-kde-done
HEREDOC
exit 0
fi


if [[ ! -z $build_steam ]] && [[ ! -f 'tmp/gentoox-steam-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
yes | layman -a steam-overlay -q
USE="abi_x86_32" emerge -O gpm
echo -e '\n# steam
app-arch/bzip2 abi_x86_32
dev-libs/elfutils abi_x86_32
dev-libs/expat abi_x86_32
dev-libs/icu abi_x86_32
dev-libs/libffi abi_x86_32
dev-libs/libpthread-stubs abi_x86_32
dev-libs/libxml2 abi_x86_32
dev-libs/ocl-icd abi_x86_32
dev-libs/wayland abi_x86_32
dev-util/glslang abi_x86_32
dev-util/pkgconf abi_x86_32
media-libs/mesa abi_x86_32
sys-apps/lm-sensors abi_x86_32
sys-devel/clang abi_x86_32
sys-devel/llvm abi_x86_32
sys-libs/gpm abi_x86_32
sys-libs/ncurses abi_x86_32
sys-libs/zlib abi_x86_32
virtual/libelf abi_x86_32
virtual/libffi abi_x86_32
virtual/opengl abi_x86_32
virtual/pkgconfig abi_x86_32
x11-base/xcb-proto abi_x86_32
x11-libs/libdrm abi_x86_32
x11-libs/libpciaccess abi_x86_32
x11-libs/libva abi_x86_32
x11-libs/libva-intel-driver abi_x86_32
x11-libs/libva-vdpau-driver abi_x86_32
x11-libs/libvdpau abi_x86_32
x11-libs/libX11 abi_x86_32
x11-libs/libXau abi_x86_32
x11-libs/libxcb abi_x86_32
x11-libs/libXdamage abi_x86_32
x11-libs/libXdmcp abi_x86_32
x11-libs/libXext abi_x86_32
x11-libs/libXfixes abi_x86_32
x11-libs/libXrandr abi_x86_32
x11-libs/libXrender abi_x86_32
x11-libs/libxshmfence abi_x86_32
x11-libs/libXv abi_x86_32
x11-libs/libXvMC abi_x86_32
x11-libs/libXxf86vm abi_x86_32' >> /etc/portage/package.use/gentoox
emerge -av steam-meta
touch /tmp/gentoox-steam-done
HEREDOC
exit 0
fi


if [[ ! -z $build_extra ]] && [[ ! -f 'tmp/gentoox-extra-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"

echo -e '\nmedia-gfx/gimp heif jpeg2k openexr python vector-icons webp wmf xpm
media-video/ffmpeg bluray cdio dav1d rubberband libass ogg vpx rtmp aac wavpack opus gme v4l webp theora xcb cpudetection x265 libaom truetype libsoxr modplug vdpau
dev-lang/php gd truetype pcntl zip curl sockets' >> /etc/portage/package.use/gentoox

yes | layman -a bobwya -q
mkdir -p /etc/portage/package.mask /etc/portage/package.unmask
echo '*/*::bobwya' >> /etc/portage/package.mask/lowprio
echo 'app-benchmarks/phoronix-test-suite::bobwya' >> /etc/portage/package.unmask/wanted
echo 'dev-php/fpdf::bobwya' >> /etc/portage/package.unmask/wanted

emerge -v gimp avidemux blender tuxkart phoronix-test-suite # libreoffice
touch /tmp/gentoox-extra-done
HEREDOC
exit 0
fi


if [[ ! -z $configure_user ]] && [[ ! -f 'tmp/gentoox-user-configured' ]]; then
cp ../../install.sh usr/src/
cp ../../postinstall.sh usr/src/
mkdir usr/src/theme
cp ../../1518039301698.png usr/src/theme/
cp '../../GentooX Breeze Dark Transparent.tar.gz' usr/src/theme/
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
sed -i "s/localhost/gentoox/g" /etc/conf.d/hostname
sed -i "s/127.0.0.1	localhost/127.0.0.1	gentoox.haxx.dafuq gentoox localhost/" /etc/hosts
sed -i "s/::1		localhost/::1		gentoox.haxx.dafuq gentoox localhost/" /etc/hosts
echo 'dns_domain_lo="haxx.local"
nis_domain_lo="haxx.local"' > /etc/conf.d/net
echo 'nameserver 1.1.1.1
nameserver 2606:4700:4700::1111' > /etc/resolv.conf

# theme related
(cd /usr/share/icons; git clone https://github.com/keeferrourke/la-capitaine-icon-theme.git)
cd /usr/src/
git clone https://github.com/ishovkun/SierraBreeze.git
cd SierraBreeze/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make install
cd /

#echo "root:$rootpassword" | chpasswd
yes "$rootpassword" | passwd root
useradd $username
yes "$userpassword"  | passwd "$username"
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

usermod -aG users,portage,lp,adm,audio,cdrom,disk,games,input,usb,video,cron $username

cp /etc/samba/smb.conf.default /etc/samba/smb.conf
sed -i "s/   workgroup = MYGROUP/   workgroup = WORKGROUP/" /etc/samba/smb.conf
rc-update add dbus default
rc-update add dhcpcd default
rc-update add avahi-daemon default
rc-update add samba default


cp /usr/src/install.sh /home/$username/
cp /usr/src/postinstall.sh /home/$username/
cd /home/$username/
echo '~/postinstall.sh &' >> .xinitrc
echo 'exec dbus-launch --exit-with-session startplasma-x11' >> .xinitrc
chown -R $username /home/$username/
su - gentoox

touch /tmp/gentoox-user-configured
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
cat <<HEREDOC | chroot .
  rm -f /tmp/*
  rm -rf /var/tmp/portage/*
  history -c
  history -w
HEREDOC
cd ..
umount -l image/var/cache/{binpkgs,distfiles}
umount -l image/*
mksquashfs image/ image.squashfs -b 1M -comp zstd -Xcompression-level 10
mkdir iso/
isobuilddate=$(wget -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/ | sed -nr "s/.*href=\"install-amd64-minimal-([0-9].*).iso\">.*/\1/p")
if [[ ! -f "current-install-amd64-minimal/install-amd64-minimal-$isobuilddate.iso" ]]; then
  wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/install-amd64-minimal-$isobuilddate.iso
fi
xorriso -osirrox on -indev *-$isobuilddate.iso -extract / iso/
mv image.squashfs iso/image.squashfs
tar -xOf kernel-gentoox.tar.lzma --wildcards \*vmlinuz-\* > iso/boot/gentoo
tar -xOf kernel-gentoox.tar.lzma --wildcards \*initramfs-\* | xz -d | gzip > iso/boot/gentoo.igz
tar -xOf kernel-gentoox.tar.lzma --wildcards \*System.map-\* > iso/boot/System-gentoo.map
sed -i "s@dokeymap@aufs@g" iso/isolinux/isolinux.cfg
sed -i "s@dokeymap@aufs@g" iso/grub/grub.cfg
xorriso -as mkisofs -r -J \
	-joliet-long -l -cache-inodes \
	-isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
	-partition_offset 16 -A "GentooX Live" \
	-b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e gentoo.efimg -no-emul-boot -isohybrid-gpt-basdat \
    -V "GentooX Live" -o GentooX-x86_64-$builddate.iso iso/
#rm -Rf image/ iso/ kernel-gentoox.tar.lzma
fi

