# GentooX

GentooX is an -O3 and LTO optimized x86_64 LiveCD Gentoo distribution with a simple *install.sh* CLI installer. GentooX supports BIOS and UEFI x86_64 systems, at minimum requires ~~AVX~~ capable CPUs released since 2011 such as Intel Sandybridge or AMD Bulldozer, and among KDE, it includes Steam, flatpak, and phoronix-suite out-of-the-box.

* based on Gentoo's bleeding edge ~amd64 testing branch
* OpenRC init system
* latest KDE Desktop Environment with custom GentooX theme, global menus enabled by default, latte dock
* Firefox global menu support patched in, OpenGL acceleration enabled by default, PGO build
* [gentooLTO overlay](https://github.com/InBetweenNames/gentooLTO)
* BTRFS used by default with lzo compression and snapshot setup modeled after openSUSE
* phoronix-suite available out-of-the-box for benchmarking purposes
* Steam installed out-of-the-box with necessary lib32 dependencies and fsync Linux kernel patched in
* flatpak is included, easily install VSCode or Discord in sandboxed environment
* Wine with vkd3d support included out-of-the-box
* ZFS support, kernel patched to export FPU functions
* Linux 5.18.11 kernel built with 1000Hz clock resolution and -03 optimization level. Patches include aufs, zstd, ClearLinux patches, Valve's fsync, [sirlucjan's](https://gitlab.com/sirlucjan/kernel-patches/-/tree/master/) patches: android-patches / amd64-patches / arch-patches / bbr2-patches / btrfs-patches / cpu-patches / cpufreq-patches / fixes-miscellaneous / hwmon-patches / intel-patches / lru-patches / lqx-patches / mm-patches / ntfs / v4l2loopback-patches / zstd-patches / xanmod-patches / zstd-dev-patches.
* KDE 5.25.3, KDE Applications 22.04.3, KDE Frameworks 5.96.0, Qt 5.15.5
* CacULE CPU scheduler, CPU frequency scaling governor set to performance
* Secure Boot is supported, kernel and modules have been signed, before you can install the OS under Secure Boot, import MOK.der in your BIOS via "Append Default db" (answer "no" and find the MOK.der on flashdrive where ISO has been written)

## Download
http://gentoox.cryptohash.nl/

![kicker](https://raw.githubusercontent.com/fatalhalt/gentoox/master/screenshots/kicker.jpg?raw=true)

![dolphin](https://raw.githubusercontent.com/fatalhalt/gentoox/master/screenshots/dolphin.jpg?raw=true)

The ISO weighs around 4GB and following settings were used to build it:
## CFLAGS
```sh
source make.conf.lto
COMMON_FLAGS="-O3 -march=sandybridge -mtune=sandybridge -pipe -fomit-frame-pointer -fno-math-errno -fno-trapping-math -funroll-loops -mfpmath=both -malign-data=cacheline -fgraphite-identity -floop-nest-optimize -fdevirtualize-at-ltrans -fipa-pta -fno-semantic-interposition -flto=4 -fuse-linker-plugin"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=sandybridge"
LDFLAGS="${COMMON_FLAGS} ${LDFLAGS} -Wl,-O1 -Wl,--as-needed -Wl,-fuse-ld=mold"
CPU_FLAGS_X86="aes mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
```
## USE flags
```sh
USE="-bindist elogind -consolekit -systemd udev dbus X wayland gles vulkan plymouth pulseaudio screencast ffmpeg ipv6 bluetooth zstd avif heif jpeg2k webp -webkit"
```
## FAQ
> (Q) **what are the user/password credentials for LiveCD?**

**gentoox** and **gentoox**
> (Q) **what is the main motivation behind GentooX?**

I found it rather tedious to setup a clean Gentoo install and LTO all the packages, not only gcc has to be rebuilt to support graphite, but then your entire stage3 install needs to be recompiled, not to mention already installed software. GentooX aims to provide pre-compiled and LTOed packages from the get go with easy installation and convenient LiveCD. Since GentooX mandates AVX support, this allows further optimizations to all packages.
> (Q) **how can I start KDE?**

login to tty1 using gentoox/gentoox and type 'startx', to start a wayland session type './startkde-wayland.sh'
> (Q) **why does theme look like it didn't apply correctly? e.g. fonts are enlarged or dolphin looks dark-and-white?**

make sure to logout/login after initial 'startx' startup in LiveCD or after installation
> (Q) **what are the minimum requirements?**

any AVX capable CPUs released since 2011 such as Intel Sandybridge or AMD Bulldozer, 4GB of RAM (mostly due to LiveCD being 4GB squashfs file), and 16GB of disk space for root partition where openSUSE's style BTRFS will be setup and 128MB boot partition
> (Q) **how can GentooX be installed?**

boot LiveCD, login with gentoox/gentoox credentials, sudo su, and run ./install.sh, the install script is interactive, BIOS and UEFI systems are supported
> (Q) **how does the installation work?**

The installation carried by install.sh is very simple, besides interactive partitioning the setup extracts 4GB image.squashfs into root partition that ends up taking 13GB of space which includes all the pre-compiled software such as KDE and Steam.
> (Q) **is GentooX source based? How can I install additional software or update the system after installation?**

GentooX is source based, you should run **emerge --sync** after the install. After that, to update the system run:
```sh
emerge -avuDN --with-bdeps=y --exclude gentoo-sources --exclude grub --exclude shim --exclude osl @world
```
> (Q) **can I use login manager such as SDDM instead of 'startx'?**

yes, SDDM can be enabled, follow https://wiki.gentoo.org/wiki/SDDM#Service
> (Q) **how does the custom GentooX KDE theme get applied?**

when 'startx' is issued the ~/.xinitrc contains a 1-time line to run /usr/src/postinstall.sh
> (Q) **can I build GentooX from scratch myself? Could I e.g. optimize it solely for 3rd Gen AMD Ryzen?**

Yes! I will include a write up at some point. Building GentooX from scratch involves building a stage3 tarball with help of build-stage3.sh and then building actual GentooX with gentoox_build.sh
> (Q) **why GentooX name?**
 
I couldn't come up with anything better at time, I know there's a Gentoo distribution aimed at original XBOX named 'gentoox'. My distro uses capital X at the end for now (Gentoo**X**).

## Credits
Gentoo project, https://www.gentoo.org/, note: Gentoo Foundation, Inc. is the owner of the Gentoo trademark.
CloverOS, https://cloveros.ga/, GentooX has been heavily inspired by CloverOS, if you want fvwm based optimized Gentoo distribution, look no further!

## Known issues
* grub-2.06-r2 and shim-15.6 break Secure Boot  (ISO comes with older grub-2.06-r1 and shim-15.5-r1 packages)
* dolphin fails to mount smb shares with samba 4.16.x (workaround: in KDE System Settings prefill user/password in 'Windows Shares' section)
 
