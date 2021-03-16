#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

#
# Notes
# • start with clean /var/db/, if you have binpkgs or distfiles on a host you can mount --bind or rsync them to the chroot
# • plymouth graphical splash via genkernel-next is commented out as it only supports systemd, GentooX is using OpenRC
# • CONFIG_ISO9660_FS=y must be compiled-in and not 'm' otherwise livecd won't boot, squashfs cannot be bigger than 4GB, also empty 'livecd' file should exist on iso's /
#
# host dependencies
#   base install: genkernel btrfs-progs portage-utils gentoolkit cpuid2cpuflags cryptsetup lvm2 mdadm dev-vcs/git
#

gitprefix="https://gitgud.io/cloveros/cloveros/raw/master"
rootpassword=gentoox
username=gentoox
userpassword=gentoox
builddate="$(date +%Y%m%d).graphite"
builddir="build-$(date +%Y%m%d)"
stage3tarball="stage3-amd64-20201208.graphite.tar.xz"
KERNEL_CONFIG_DIFF="0001-kernel-config-cfs-r7.patch"

binpkgs="$(pwd)/var/cache/binpkgs/"
distfiles="$(pwd)/var/cache/distfiles/"

#build_weston=y
#build_kde=y
#build_steam=y
#build_extra=y
#build_wine=y
#configure_user=y
#configure_weston=y
#clover_rice="y"
#build_iso=y


if [[ ! -d $builddir ]]; then mkdir -v $builddir; fi
cd $builddir

if [[ ! -f 'image/etc/gentoo-release' ]]; then
  ntpd -qg
  mkdir image/
  cd image/

  if [[ -f "../../$stage3tarball" ]]; then
    cp -v "../../$stage3tarball" .
  else
    cp -v /var/tmp/catalyst/builds/default/stage3-amd64-$builddate.tar.xz .
  fi
  if [[ $? -ne 0 ]]; then echo "you need to build stage3 tarball that has gcc graphite support first via build-stage3.sh"; exit 1; fi

  echo 'extracting stage3 tarball...'
  tar xJpf stage3* --xattrs --numeric-owner
  rm -f stage3*

  cp ../../$KERNEL_CONFIG_DIFF usr/src
  cp ../../0011-ZFS-fix.patch usr/src
  cp ../../portage-change-rsync-to-git-repos.diff usr/src
  cp ../../zfs-ungpl-rcu_read_unlock-export.diff usr/src
  mkdir -p etc/portage/patches
  cp -r ../../patches/* etc/portage/patches/
  mkdir -p etc/portage/patches/app-crypt/efitools
  cp ../../efitools-1.9.2-fixup-UNKNOWN_GLYPH.patch etc/portage/patches/app-crypt/efitools/
  cp ../../60-ioschedulers.rules etc/udev/rules.d/

  mkdir -p etc/portage/patches/www-client/firefox
  wget --quiet -P etc/portage/patches/www-client/firefox/ 'https://raw.githubusercontent.com/bmwiedemann/openSUSE/master/packages/m/MozillaFirefox/firefox-kde.patch'
  wget --quiet -P etc/portage/patches/www-client/firefox/ 'https://raw.githubusercontent.com/bmwiedemann/openSUSE/master/packages/m/MozillaFirefox/mozilla-kde.patch'
  wget --quiet -P etc/portage/patches/www-client/firefox/ 'https://bazaar.launchpad.net/~mozillateam/firefox/firefox-trunk.head/download/ricotz%40ubuntu.com-20210119184254-9ag3yy5sw3i4autd/unitymenubar.patch-20130215095938-1n6mqqau8tdfqwhg-1/unity-menubar.patch'

  mkdir -p etc/portage/package.mask
  mkdir -p etc/portage/package.unmask
  cp ../../package.mask/* etc/portage/package.mask/

  cp ../../arch-chroot usr/local/sbin/
  cp ../../genfstab usr/local/sbin/

  cp ../../mpv-kio.sh usr/local/bin/

  if [[ ! -z $binpkgs ]] && [[ ! -z $distfiles ]]; then
    #rsync -a $binpkgs var/cache/binpkgs/
    #rsync -a $distfiles var/cache/distfiles/
    mkdir -p $binpkgs
    mkdir -p $distfiles
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
  if [[ -z $(findmnt image/var/cache/binpkgs) ]]; then
    mount --bind $binpkgs image/var/cache/binpkgs/
    mount --bind $distfiles image/var/cache/distfiles/
  fi
else
  echo "proc already mounted..."
fi
cd image/

if [[ $# -ge 1 ]]; then
  case $1 in
    "chroot")
      chroot . /bin/bash -i
      #env-update
      #chmod 777 /tmp
      umount -l var/cache/binpkgs
      umount -l var/cache/distfiles
      umount -l {dev,proc,sys}
      exit 0
      ;;
  esac
fi

if [[ ! -f 'tmp/gentoox-base-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
mkdir /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
emerge-webrsync
emerge --sync
eselect profile set "default/linux/amd64/17.1"
echo 'COMMON_FLAGS="-O3 -march=sandybridge -mtune=sandybridge -pipe -fomit-frame-pointer -fno-math-errno -fno-trapping-math -funroll-loops -mfpmath=both -malign-data=cacheline -fgraphite-identity -floop-nest-optimize -fdevirtualize-at-ltrans -fipa-pta -fno-semantic-interposition -flto=8 -fuse-linker-plugin"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=sandybridge"
#LDFLAGS="\${COMMON_FLAGS} \${LDFLAGS} -Wl,-O1 -Wl,--as-needed -Wl,-fuse-ld=bfd"
CPU_FLAGS_X86="aes mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
MAKEOPTS="-j8"
USE="-bindist"
#FEATURES="buildpkg noclean"
FEATURES="buildpkg"
ACCEPT_KEYWORDS="~amd64"
ACCEPT_LICENSE="*"
PORTAGE_NICENESS=19
GENTOO_MIRRORS="https://gentoo.osuosl.org/"
EMERGE_DEFAULT_OPTS="--jobs=2"
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"
LC_MESSAGES=C
RUBY_TARGETS="ruby27 ruby30"' > /etc/portage/make.conf

mkdir /etc/portage/env
echo 'CFLAGS="\${CFLAGS} -fno-lto"
CXXFLAGS="\${CFLAGS} -fno-lto"' > /etc/portage/env/nolto.conf
echo 'CFLAGS="-O2 -march=sandybridge -mtune=sandybridge -pipe"
CXXFLAGS="\${CFLAGS}"' > /etc/portage/env/O2nolto.conf
echo 'CFLAGS="-O3 -march=sandybridge -mtune=sandybridge -pipe"
CXXFLAGS="\${CFLAGS}"' > /etc/portage/env/O3nolto.conf

echo 'sys-libs/glibc nolto.conf
dev-libs/elfutils nolto.conf
app-crypt/efitools nolto.conf
sys-libs/efivar nolto.conf
dev-libs/libaio nolto.conf
app-arch/bzip2 O3nolto.conf
media-libs/opencv O3nolto.conf' > /etc/portage/package.env

echo 'sys-devel/gcc graphite lto pgo zstd
dev-libs/elfutils zstd
sys-libs/glibc custom-cflags
sys-devel/llvm gold
sys-apps/kmod lzma
sys-kernel/linux-firmware initramfs redistributable unknown-license
x11-libs/libdrm libkms
media-libs/mesa d3d9 lm-sensors opencl vaapi vdpau vulkan vulkan-overlay xa xvmc
media-libs/libsdl2 gles2
www-client/firefox -system-av1 -system-icu -system-jpeg -system-libevent -system-libvpx -system-sqlite -system-harfbuzz -system-webp hwaccel pgo lto wayland clang
dev-libs/boost python zstd
dev-lang/python sqlite
sys-fs/squashfs-tools zstd
sys-boot/grub:2 mount libzfs
x11-libs/libxcb xkb
dev-db/sqlite secure-delete
x11-base/xorg-server xvfb
sys-apps/xdg-desktop-portal screencast
dev-vcs/git tk
dev-libs/libjcat pkcs7 gpg
dev-libs/libdbusmenu gtk3
net-misc/curl http2
dev-libs/apr-util ldap
sys-apps/util-linux caps
*/* PYTHON_TARGETS: python2_7 python3_9
*/* PYTHON_SINGLE_TARGET: -* python3_9
media-gfx/blender python_single_target_python3_8
dev-libs/libnatspec python_single_target_python2_7
dev-lang/yasm python_single_target_python2_7
media-libs/libcaca python_single_target_python2_7
gnome-base/libglade python_single_target_python2_7' > /etc/portage/package.use/gentoox

rm -rf /etc/portage/package.accept_keywords/
echo -n > /etc/portage/package.accept_keywords

#unmask gcc/glibc to prompt installation of masked 9999 packages
echo 'sys-devel/gcc' >> /etc/portage/package.unmask/gcc
echo 'sys-devel/gcc **' >> /etc/portage/package.accept_keywords
echo 'sys-libs/glibc' >> /etc/portage/package.unmask/glibc
echo 'sys-libs/glibc **' >> /etc/portage/package.accept_keywords

emerge -v1 gcc  # install latest gcc now that it has been unmasked
emerge -v gentoo-sources  # presence of /usr/src/linux is required below
emerge --autounmask=y --autounmask-write=y -veDN --with-bdeps=y --exclude gcc @world  # rebuild entire system with new gcc

emerge -v genkernel portage-utils gentoolkit cpuid2cpuflags cryptsetup lvm2 mdadm dev-vcs/git btrfs-progs app-arch/lz4 ntfs3g dosfstools exfat-utils f2fs-tools gptfdisk efitools shim syslog-ng logrotate
emerge --noreplace app-editors/nano

# set portage to use git repos
patch -p1 < /usr/src/portage-change-rsync-to-git-repos.diff
rm -rf /var/db/repos/gentoo/*
rm -rf /var/db/repos/gentoo/.*
emerge --sync

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
  wget --quiet 'https://git.archlinux.org/svntogit/packages.git/plain/trunk/config?h=packages/linux' -O .config
  #wget --quiet -m -np -c 'ck.kolivas.org/patches/5.0/5.11/5.11-ck1/patches/'
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/android-patches-v2/0001-android-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/arch-patches-v6/0001-arch-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/btrfs-patches-v5/0001-btrfs-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/clearlinux-patches/0001-clearlinux-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/cpu-patches/0001-cpu-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/fixes-miscellaneous-v7/0001-fixes-miscellaneous.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/mm-patches-v3/0001-mm-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/futex-dev-patches/0001-futex-dev-patches.patch
  #wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/futex2-dev-trunk-patches-v4/0001-futex2-resync-from-gitlab.collabora.com.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/ntfs3-patches-v3/0001-ntfs3-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/zstd-dev-patches/0001-zstd-dev-patches.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/zstd-patches/0001-init-add-support-for-zstd-compressed-modules.patch
  wget --quiet https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/5.11/zswap-patches-v2/0001-zswap-patches.patch
  wget --quiet https://raw.githubusercontent.com/hamadmarri/cacule-cpu-scheduler/master/patches/CacULE/v5.11/cacule-5.11.patch

  #for f in ck.kolivas.org/patches/5.0/5.11/5.11-ck1/patches/*.patch; do patch -p1 < "\$f"; done
  patch -p1 < 0001-cpu-patches.patch
  patch -p0 < ../$KERNEL_CONFIG_DIFF

  # Aufs
  git clone --single-branch --branch aufs5.x-rcN https://github.com/sfjro/aufs5-standalone.git
  cp -r aufs5-standalone/fs/aufs/ fs/
  cp aufs5-standalone/include/uapi/linux/aufs_type.h include/uapi/linux/
  patch -p1 < aufs5-standalone/aufs5-kbuild.patch
  patch -p1 < aufs5-standalone/aufs5-base.patch
  patch -p1 < aufs5-standalone/aufs5-mmap.patch
  patch -p1 < aufs5-standalone/aufs5-standalone.patch
  echo -e "CONFIG_AUFS_FS=y\nCONFIG_AUFS_BRANCH_MAX_127=y\nCONFIG_AUFS_BRANCH_MAX_511=n\nCONFIG_AUFS_BRANCH_MAX_1023=n\nCONFIG_AUFS_BRANCH_MAX_32767=n\nCONFIG_AUFS_HNOTIFY=y\nCONFIG_AUFS_EXPORT=n\nCONFIG_AUFS_XATTR=y\nCONFIG_AUFS_FHSM=y\nCONFIG_AUFS_RDU=n\nCONFIG_AUFS_DIRREN=n\nCONFIG_AUFS_SHWH=n\nCONFIG_AUFS_BR_RAMFS=y\nCONFIG_AUFS_BR_FUSE=n\nCONFIG_AUFS_BR_HFSPLUS=n\nCONFIG_AUFS_DEBUG=n" >> .config
  sed -i "s/CONFIG_ISO9660_FS=m/CONFIG_ISO9660_FS=y/" .config

  # Anbox
  patch -p1 < 0001-android-patches.patch
  scripts/config --enable CONFIG_ASHMEM
  scripts/config --enable CONFIG_ANDROID
  scripts/config --enable CONFIG_ANDROID_BINDER_IPC
  scripts/config --enable CONFIG_ANDROID_BINDERFS
  scripts/config --set-str CONFIG_ANDROID_BINDER_DEVICES "binder,hwbinder,vndbinder"

  patch -p1 < 0001-arch-patches.patch
  patch -p1 < 0001-btrfs-patches.patch
  patch -p1 < 0001-clearlinux-patches.patch
  patch -p1 < 0001-fixes-miscellaneous.patch
  patch -p1 < 0001-mm-patches.patch
  patch -p1 < 0001-futex-dev-patches.patch
  #patch -p1 < 0001-futex2-resync-from-gitlab.collabora.com.patch
  patch -p1 < ../0011-ZFS-fix.patch
  patch -p1 < ../zfs-ungpl-rcu_read_unlock-export.diff
  patch -p1 < 0001-ntfs3-patches.patch
  patch -p1 < 0001-zstd-dev-patches.patch
  patch -p1 < 0001-init-add-support-for-zstd-compressed-modules.patch
  patch -p1 < 0001-zswap-patches.patch
  patch -p1 < cacule-5.11.patch
  sed -i 's/CONFIG_DEFAULT_HOSTNAME="archlinux"/CONFIG_DEFAULT_HOSTNAME="gentoox"/' .config
  sed -i 's/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="-x86_64"/' .config
  sed -i 's/CONFIG_SQUASHFS=m/CONFIG_SQUASHFS=y/' .config
  sed -i 's/CONFIG_BLK_DEV_LOOP=m/CONFIG_BLK_DEV_LOOP=y/' .config
  sed -i 's/CONFIG_BLK_DEV_CRYPTOLOOP=m/CONFIG_BLK_DEV_CRYPTOLOOP=y/' .config
  sed -i 's/CONFIG_NET_IP_TUNNEL=y/CONFIG_NET_IP_TUNNEL=m/' .config
  sed -i 's/CONFIG_NET_UDP_TUNNEL=y/CONFIG_NET_UDP_TUNNEL=m/' .config
  sed -i 's/EXTRAVERSION = -gentoo-r1/EXTRAVERSION = -gentoo/' Makefile
  make oldconfig
  touch /tmp/gentoox-kernelpatches-applied
fi

cd /usr/src
#rm -f $KERNEL_CONFIG_DIFF
#mkdir -p /usr/share/genkernel/distfiles/
#wget https://www.busybox.net/downloads/busybox-1.20.2.tar.bz2 -d /usr/share/genkernel/distfiles/
#echo -e '\nMAKEOPTS="-j12"' >> /etc/genkernel.conf

# former command is genkernel-next (systemd only), latter is for genkernel
#genkernel --kernel-config=/usr/src/linux-\$KERNELVERSION-gentoo/.config --no-mrproper --udev --plymouth --luks --lvm --mdadm --btrfs --zfs all
genkernel --kernel-config=/usr/src/linux-\$KERNELVERSION-gentoo/.config --no-mrproper kernel

#unmask zfs to prompt installation of masked zfs-9999 zfs-kmod-9999
echo 'sys-fs/zfs
sys-fs/zfs-kmod' >> /etc/portage/package.unmask/zfs
echo 'sys-fs/zfs **
sys-fs/zfs-kmod **' >> /etc/portage/package.accept_keywords
emerge -v grub:2 squashfs-tools linux-firmware os-prober zfs zfs-kmod
hostid > /etc/hostid
dd if=/dev/urandom of=/dev/stdout bs=1 count=4 > /etc/hostid

genkernel --kernel-config=/usr/src/linux/.config --compress-initramfs-type=zstd --microcode --luks --lvm --mdadm --btrfs --zfs initramfs
tar --zstd -cf /usr/src/kernel-gentoox.tar.zst /boot/*\${KERNELVERSION}* -C /lib/modules/ .

sed -i "s/#GRUB_CMDLINE_LINUX_DEFAULT=\"\"/GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=z3fold dobtrfs\"/" /etc/default/grub
sed -i "s/#GRUB_GFXMODE=640x480/GRUB_GFXMODE=auto/" /etc/default/grub
sed -i "s/#GRUB_GFXPAYLOAD_LINUX=/GRUB_GFXPAYLOAD_LINUX=keep/" /etc/default/grub
rc-update add zfs-import boot
rc-update add zfs-mount boot
touch /tmp/gentoox-kernel-done
HEREDOC
cp -v usr/src/kernel-gentoox.tar.lzma ../
exit 0
else echo "kernel already compiled, skipping..."; fi


if [[ ! -z $build_weston ]] && [[ ! -f 'tmp/gentoox-weston-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
sed -i -r "s/^USE=\"([^\"]*)\"$/USE=\"\1 elogind -consolekit -systemd udev dbus X wayland gles vulkan plymouth pulseaudio ffmpeg ipv6 infinality bluetooth zstd\"/g" /etc/portage/make.conf

# install lto-overlay
emerge layman
layman --sync-all
yes | layman --add mv
yes | layman --add lto-overlay
echo 'sys-config/ltoize ~amd64
app-portage/portage-bashrc-mv ~amd64
app-shells/runtitle ~amd64' >> /etc/portage/package.accept_keywords
mkdir -p /etc/portage/package.mask /etc/portage/package.unmask
echo '*/*::mv' >> /etc/portage/package.mask/lowprio
echo 'app-portage/portage-bashrc-mv::mv
app-shells/runtitle::mv' >> /etc/portage/package.unmask/wanted
emerge sys-config/ltoize
sed -i '1s/^/source make.conf.lto\n/' /etc/portage/make.conf
sed -i '1s/^/NTHREADS="8"\n/' /etc/portage/make.conf

FEATURES="-userpriv" emerge dev-lang/yasm  # yasm fails to build otherwise

#echo 'sys-kernel/genkernel-next plymouth
#sys-boot/plymouth gdm' > /etc/portage/package.use/gentoox

emerge -v --autounmask=y --autounmask-write=y --keep-going=y --deep --newuse xorg-server nvidia-firmware arandr elogind sudo vim weston wpa_supplicant ntp bind-tools telnet-bsd snapper \
nfs-utils cifs-utils samba dhcpcd nss-mdns zsh zsh-completions powertop cpupower lm-sensors screenfetch gparted gdb strace atop dos2unix app-misc/screen app-text/tree openbsd-netcat laptop-mode-tools hdparm #plymouth-openrc-plugin
#emerge -avuDN --with-bdeps=y @world
#emerge -v --depclean
touch /tmp/gentoox-weston-done
HEREDOC
exit 0
fi


if [[ ! -z $build_kde ]] && [[ ! -f 'tmp/gentoox-kde-done' ]]; then
cp ../../postinstall.sh usr/src/
mkdir usr/src/theme
cp ../../1518039301698.png usr/src/theme/
cp '../../GentooX Breeze Dark Transparent.tar.gz' usr/src/theme/

cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
eselect profile set "default/linux/amd64/17.1/desktop/plasma"
sed -i -r "s/^USE=\"([^\"]*)\"$/USE=\"\1 -webkit\"/g" /etc/portage/make.conf

# theme related
(cd /usr/share/icons; git clone https://github.com/keeferrourke/la-capitaine-icon-theme.git)
cd /usr/src/
git clone https://github.com/ishovkun/SierraBreeze.git
cd SierraBreeze/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make install
cd /

echo -e '\nkde-apps/kdecore-meta -webengine
kde-plasma/kde-cli-tools kdesu
kde-apps/akonadi -mysql sqlite
kde-plasma/plasma-meta discover networkmanager thunderbolt
kde-apps/kio-extras samba
media-video/vlc archive bluray dav1d libass libcaca lirc live opus samba speex skins theora vaapi v4l vdpau x265
media-video/ffmpeg bluray cdio dav1d rubberband libass ogg vpx rtmp aac wavpack opus gme v4l webp theora xcb cpudetection x265 libaom truetype libsoxr modplug samba vaapi vdpau libcaca libdrm librtmp opencl openssl speex
dev-qt/qtmultimedia gstreamer
gnome-base/gvfs afp archive bluray fuse gphoto2 ios mtp nfs samba zeroconf
net-irc/telepathy-idle python_single_target_python2_7' >> /etc/portage/package.use/gentoox

# enable flatpak backend in discover, patch qt-creator to use clang9 effectively dropping clang8
echo 'kde-plasma/discover flatpak' >> /etc/portage/package.use/gentoox
ebuild /var/db/repos/gentoo/kde-plasma/discover/discover-5.20.5.ebuild manifest
#patch -p1 /var/db/repos/gentoo/dev-qt/qt-creator/qt-creator-4.10.1.ebuild /usr/src/qt-creator-use-llvm9.patch
#ebuild /var/db/repos/gentoo/dev-qt/qt-creator/qt-creator-4.10.1.ebuild manifest

# mask qt-creator, it pulls llvm9 and we don't want that
echo 'dev-qt/qt-creator' >> /etc/portage/package.mask/gentoox
emerge -v --jobs=2 --keep-going=y --autounmask=y --autounmask-write=y --deep --newuse kde-plasma/plasma-meta kde-apps/kde-apps-meta kde-apps/kmail kde-apps/knotes \
latte-dock plasma-sdk libdbusmenu gvfs calamares kuroo
#emerge --noreplace dev-qt/qt-creator
#echo 'dev-qt/qt-creator' >> /etc/portage/package.mask/gentoox

#yes | layman -o https://raw.githubusercontent.com/fosero/flatpak-overlay/master/repositories.xml -f -a flatpak-overlay -q
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
x11-libs/libXxf86vm abi_x86_32
media-libs/libglvnd abi_x86_32
virtual/opencl abi_x86_32
app-arch/zstd abi_x86_32
dev-util/wayland-scanner abi_x86_32' >> /etc/portage/package.use/gentoox
emerge -v steam-meta
touch /tmp/gentoox-steam-done
HEREDOC
exit 0
fi


if [[ ! -z $build_extra ]] && [[ ! -f 'tmp/gentoox-extra-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"

echo -e '\nmedia-gfx/gimp heif jpeg2k openexr python vector-icons webp wmf xpm python_single_target_python2_7
media-video/mpv archive bluray drm gbm samba vaapi vdpau
dev-lang/php gd truetype pcntl zip curl sockets
app-emulation/virtualbox-guest-additions -X' >> /etc/portage/package.use/gentoox

yes | layman -a bobwya -q
echo '*/*::bobwya' >> /etc/portage/package.mask/lowprio

echo 'app-benchmarks/phoronix-test-suite::bobwya
dev-php/fpdf::bobwya' >> /etc/portage/package.unmask/wanted

echo 'media-gfx/gimp nolto.conf
media-libs/avidemux-core
media-libs/avidemux-plugins' >> /etc/portage/package.env

emerge -v gimp avidemux blender tuxkart keepassxc libreoffice firefox adobe-flash mpv audacious-plugins audacious net-irc/hexchat smartmontools libisoburn phoronix-test-suite virtualbox-guest-additions pfl bash-completion dev-python/pip virtualenv jq
touch /tmp/gentoox-extra-done
HEREDOC
exit 0
fi


if [[ ! -z $build_wine ]] && [[ ! -f 'tmp/gentoox-wine-done' ]]; then
cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"

echo -e '\n# wine
x11-libs/libXcursor abi_x86_32
x11-libs/libXi abi_x86_32
media-libs/alsa-lib abi_x86_32
net-print/cups abi_x86_32
media-libs/fontconfig abi_x86_32
media-libs/lcms abi_x86_32
media-sound/mpg123 abi_x86_32
sys-devel/gettext abi_x86_32
media-libs/libpng abi_x86_32
media-sound/pulseaudio abi_x86_32
media-libs/libsdl2 abi_x86_32 haptic
net-libs/gnutls abi_x86_32
media-libs/freetype abi_x86_32
sys-apps/dbus abi_x86_32
sys-libs/libunwind abi_x86_32
media-libs/vulkan-loader abi_x86_32
x11-libs/libXcomposite abi_x86_32
dev-libs/libxslt abi_x86_32
app-emulation/wine-gecko abi_x86_32
dev-libs/libgcrypt abi_x86_32
dev-libs/libgpg-error abi_x86_32
dev-libs/libtasn1 abi_x86_32
dev-libs/libunistring abi_x86_32
dev-libs/nettle abi_x86_32
dev-libs/gmp abi_x86_32
net-dns/libidn2 abi_x86_32
x11-libs/libxkbcommon abi_x86_32
media-libs/libsndfile abi_x86_32
x11-libs/libSM abi_x86_32
x11-libs/libICE abi_x86_32
x11-libs/libXtst abi_x86_32
sys-libs/libcap abi_x86_32
dev-libs/glib abi_x86_32
sys-apps/tcp-wrappers abi_x86_32
net-libs/libasyncns abi_x86_32
media-plugins/alsa-plugins abi_x86_32
media-video/ffmpeg abi_x86_32
media-libs/libbluray abi_x86_32
dev-libs/libcdio-paranoia abi_x86_32
media-libs/dav1d abi_x86_32
media-sound/lame abi_x86_32
media-libs/libtheora abi_x86_32
media-libs/libogg abi_x86_32
media-libs/libwebp abi_x86_32
media-libs/x264 abi_x86_32
media-libs/x265 abi_x86_32
media-libs/xvid abi_x86_32
media-libs/game-music-emu abi_x86_32
media-libs/libaom abi_x86_32
media-libs/libass abi_x86_32
media-libs/libcaca abi_x86_32
media-video/rtmpdump abi_x86_32
media-libs/soxr abi_x86_32
media-libs/libmodplug abi_x86_32
media-libs/opus abi_x86_32
media-libs/rubberband abi_x86_32
net-fs/samba abi_x86_32
media-libs/speex abi_x86_32
gnome-base/librsvg abi_x86_32
media-libs/libvorbis abi_x86_32
media-libs/libvpx abi_x86_32
dev-libs/openssl abi_x86_32
x11-libs/cairo abi_x86_32
x11-libs/gdk-pixbuf abi_x86_32
media-libs/harfbuzz abi_x86_32
x11-libs/pango abi_x86_32
dev-libs/fribidi abi_x86_32
x11-libs/libXft abi_x86_32
media-gfx/graphite2 abi_x86_32
media-libs/tiff abi_x86_32
dev-libs/lzo abi_x86_32
sys-libs/binutils-libs abi_x86_32
x11-libs/pixman abi_x86_32
app-arch/libarchive abi_x86_32
dev-libs/libbsd abi_x86_32
dev-libs/popt abi_x86_32
net-libs/libnsl abi_x86_32
sys-libs/e2fsprogs-libs abi_x86_32
sys-libs/ldb abi_x86_32
sys-libs/liburing abi_x86_32
sys-libs/talloc abi_x86_32
sys-libs/tdb abi_x86_32
sys-libs/tevent abi_x86_32
dev-python/subunit abi_x86_32
app-crypt/mit-krb5 abi_x86_32
dev-util/cmocka abi_x86_32
net-libs/libtirpc abi_x86_32
sys-apps/keyutils abi_x86_32
dev-libs/check abi_x86_32
dev-util/cppunit abi_x86_32
dev-db/lmdb abi_x86_32
sys-apps/attr abi_x86_32
app-arch/xz-utils abi_x86_32
media-libs/libsamplerate abi_x86_32
sci-libs/fftw abi_x86_32
media-libs/freeglut abi_x86_32
x11-libs/libXt abi_x86_32
dev-libs/libcdio abi_x86_32
dev-libs/libpcre abi_x86_32
sys-apps/util-linux abi_x86_32
sys-libs/pam abi_x86_32
sys-libs/db abi_x86_32
media-libs/flac abi_x86_32
virtual/libintl abi_x86_32
virtual/jpeg abi_x86_32
media-libs/libjpeg-turbo abi_x86_32
virtual/libiconv abi_x86_32
virtual/libcrypt abi_x86_32
virtual/glu abi_x86_32
media-libs/glu abi_x86_32
virtual/acl abi_x86_32
sys-apps/acl abi_x86_32
dev-libs/libverto abi_x86_32
dev-libs/libev abi_x86_32
virtual/rust abi_x86_32
dev-lang/rust abi_x86_32
virtual/libudev abi_x86_32
sys-fs/eudev abi_x86_32
virtual/libusb abi_x86_32
dev-libs/libusb abi_x86_32
app-emulation/vkd3d abi_x86_32
x11-libs/xcb-util abi_x86_32
x11-libs/xcb-util-keysyms abi_x86_32
x11-libs/xcb-util-wm abi_x86_32
x11-libs/xcb-util-cursor abi_x86_32
x11-libs/xcb-util-image abi_x86_32
x11-libs/xcb-util-renderutil abi_x86_32
dev-libs/libusb-compat abi_x86_32

app-emulation/wine-vanilla custom-cflags vkd3d' >> /etc/portage/package.use/gentoox

emerge -v wine
touch /tmp/gentoox-wine-done
HEREDOC
exit 0
fi


if [[ ! -z $configure_user ]] && [[ ! -f 'tmp/gentoox-user-configured' ]]; then
cp ../../install.sh usr/src/

cat <<HEREDOC | chroot .
source /etc/profile  && export PS1="(chroot) \$PS1"
sed -i "s/localhost/gentoox/g" /etc/conf.d/hostname
sed -i "s/127.0.0.1	localhost/127.0.0.1	gentoox.haxx.dafuq gentoox localhost/" /etc/hosts
sed -i "s/::1		localhost/::1		gentoox.haxx.dafuq gentoox localhost/" /etc/hosts
echo 'dns_domain_lo="haxx.dafuq"
nis_domain_lo="haxx.dafuq"' > /etc/conf.d/net
echo 'nameserver 1.1.1.1
nameserver 2606:4700:4700::1111' > /etc/resolv.conf

#echo "root:\$rootpassword" | chpasswd
yes $rootpassword | passwd root
useradd $username
yes $userpassword  | passwd $username
gpasswd -a $username wheel
gpasswd -a $username weston-launch
gpasswd -a $username vboxguest
gpasswd -a $username vboxsf

#cp /usr/share/zoneinfo/UTC /etc/localtime
echo "America/Chicago" > /etc/timezone
cp /usr/share/zoneinfo/America/Chicago /etc/localtime
echo -e '\nen_US.UTF-8 UTF-8
ja_JP.EUC-JP EUC-JP
ja_JP.UTF-8 UTF-8
ko_KR.EUC-KR EUC-KR
ko_KR.UTF-8 UTF-8
pl_PL ISO-8859-2
pl_PL.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8

echo "frozen-files=\"/etc/sudoers\"" >> /etc/dispatch-conf.conf
sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
#sed -Ei "s@c([2-6]):2345:respawn:/sbin/agetty 38400 tty@#\0@" /etc/inittab
sed -i "s@c1:12345:respawn:/sbin/agetty 38400 tty1 linux@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@" /etc/inittab
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel\nupdate_config=1" > /etc/wpa_supplicant/wpa_supplicant.conf
eselect fontconfig enable 52-infinality.conf
eselect infinality set infinality
eselect lcdfilter set infinality
emerge -v ja-ipafonts source-han-sans fira-code fira-sans

echo 'kernel.sysrq=1' >> /etc/sysctl.d/local.conf

usermod -aG users,portage,lp,adm,audio,cdrom,disk,input,usb,video,cron,tty,plugdev $username

cp /etc/samba/smb.conf.default /etc/samba/smb.conf
sed -i "s/   workgroup = MYGROUP/   workgroup = WORKGROUP/" /etc/samba/smb.conf
rc-update add dbus default
rc-update add syslog-ng default
#rc-update add dhcpcd default
rc-update add NetworkManager default
rc-update add avahi-daemon default
rc-update add bluetooth default
rc-update add samba default
rc-update add sshd default
rc-update add virtualbox-guest-additions default
rc-update add elogind boot

ln -s /usr/src/install.sh /home/$username/
ln -s /usr/src/postinstall.sh /home/$username/
cd /home/$username/
echo '~/postinstall.sh &' > .xinitrc
echo 'exec dbus-launch --exit-with-session startplasma-x11' >> .xinitrc
chown -R $username.$username /home/$username/

if [[ ! -z $configure_weston ]]; then
  su - gentoox
  echo '#!/bin/bash
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland
export COGL_RENDERER=egl_wayland
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland-egl
exec weston-launch' > weston-launch.sh
  chmod +x weston-launch.sh
fi

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
  # don't forget
  #emerge -v --depclean
  #etc-update
  eclean-dist --deep
  eclean-pkg --deep
  #rm -f /tmp/*
  #emerge @preserved-rebuild
  rm -rf /var/tmp/portage/*
  rm -f /usr/src/linux/.tmp*
  find /usr/src/linux/ -name "*.o" -exec rm -f {} \;
  find /usr/src/linux/ -name "*.ko" -exec rm -f {} \;
  rm -f /var/tmp/genkernel/*
  #rm -rf /var/cache/genkernel/*
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
mkdir iso/
isobuilddate=$(wget -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/ | sed -nr "s/.*href=\"install-amd64-minimal-([0-9].*).iso\">.*/\1/p")
if [[ ! -f "current-install-amd64-minimal/install-amd64-minimal-$isobuilddate.iso" ]]; then
  wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/install-amd64-minimal-$isobuilddate.iso
fi
emerge -u dev-libs/libisoburn sys-fs/squashfs-tools sys-boot/syslinux
xorriso -osirrox on -indev *-$isobuilddate.iso -extract / iso/
mv image.squashfs iso/image.squashfs
tar -xOf kernel-gentoox.tar.zst --wildcards \*vmlinuz-\* > iso/boot/gentoo
tar -xOf kernel-gentoox.tar.zst --wildcards \*initramfs-\* | unzstd -d | gzip > iso/boot/gentoo.igz
tar -xOf kernel-gentoox.tar.zst --wildcards \*System.map-\* > iso/boot/System-gentoo.map
sed -i "s@dokeymap@aufs scandelay=3@g" iso/isolinux/isolinux.cfg
sed -i "s@dokeymap@aufs scandelay=3@g" iso/grub/grub.cfg
xorriso -as mkisofs -iso-level 3 -r -J \
	-joliet-long -l -cache-inodes \
	-isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
	-partition_offset 16 -A "GENTOOX" \
	-b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e gentoo.efimg -no-emul-boot -isohybrid-gpt-basdat \
    -V "GENTOOX" -o GentooX-x86_64-$builddate.iso iso/
#rm -Rf image/ iso/ kernel-gentoox.tar.zst
fi

