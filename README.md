# GentooX

an -O3, Graphite, and LTO optimized x86_64 LiveCD Gentoo distribution with installer.

GentooX comes with simple interactive *install.sh* script, supports BIOS and UEFI x86_64 systems, at minimum requires ~~AVX~~ capable CPUs released since 2011 such as Intel Sandybridge or AMD Bulldozer, among KDE, it includes Steam, flatpak, and phoronix-suite out-of-the-box.

* based on Gentoo's bleeding edge ~amd64 testing branch
* OpenRC init system
* latest KDE Desktop Environment with custom GentooX theme, global menus enabled by default, latte dock
* Firefox global menu support patched in, OpenGL acceleration enabled by default, PGO build
* [gentooLTO overlay](https://github.com/InBetweenNames/gentooLTO)
* BTRFS used by default with lzo compression and snapshot setup modeled after openSUSE
* phoronix-suite available out-of-the-box for benchmarking purposes
* Steam installed out-of-the-box with necessary lib32 dependencies and fsync Linux kernel patched in
* flatpak is included, easily install VSCode or Discord in sandboxed environment
* ZFS support, kernel patched to export FPU functions
* Linux 5.9.11 kernel built with 1000Hz -03 for Sandybridge arch. Patches include aufs, zstd, ClearLinux patches, Intel FSGSBASE patches, Valve's fsync, [sirlucjan's](https://gitlab.com/sirlucjan/kernel-patches/-/tree/master/): android/arch/btrfs/fixes-miscellaneous/ntfs, unprivileged CLONE_NEWUSER, and IOMMU missing ACS capabilities overrides. CFS remains as default scheduler.
* KDE 5.20.3, KDE Applications 20.08.3, KDE Frameworks 5.76.0, Qt 5.15.2

## Changelog
* 2020.11.30 Release
  * Linux 5.9.11, KDE 5.20.3, KDE Applications 20.08.3, KDE Frameworks 5.76.0, Qt 5.15.2, Firefox 83.0, updates as of 11/30.
* 2020.10.13 Release
  * Linux 5.9.0, KDE 5.20.0, KDE Applications 20.08.2, KDE Frameworks 5.75.0, Firefox 81.0.2, updates as of 10/13.
* 2020.09.17 Release
  * Linux 5.8.10, KDE 5.19.5, KDE Applications 20.08.1, KDE Frameworks 5.74.0, Qt 5.15.1, Firefox 80.0.1, updates as of 9/17.
* 2020.08.19 Release
  * everything recompiled against GCC 10.2.0
  * Linux 5.8.2, KDE Applications 20.08, KDE Frameworks 5.73.0, Firefox 79.0, updates as of 8/19.
  * known issues: [kde global menu padding problem](https://www.reddit.com/r/kde/comments/i8tvq7/global_menu_padding_broken/)
* 2020.07.29 Release
  * Linux 5.7.11, KDE 5.19.4, KDE Applications 20.04.3, KDE Frameworks 5.72.0, Qt 5.15.0, Firefox 78.0.2, updates as of 7/29.
* 2020.06.10 Release
  * Linux 5.7.1, KDE 5.19.0, Qt 5.15.0, Firefox 77.0.1, updates as of 6/10. Compiled with GCC9.3. LLVM10 remains masked.
  * added KDE systemtray to the panel (in postinstall.sh script)
* 2020.05.11 Release
  * drop system-wide AVX CPU compile flag, it is a [net loss](https://old.reddit.com/r/Gentoo/comments/ga1tah/gentoox_202004_new_distro/foxisn2/), 2020.05.01 is the last AVX build
  * KDE 5.18.5, KDE Frameworks 5.70.0, Linux 5.6.11
  * make Python 3.7 default
  * Fix checking for UEFI_MODE during GRUB setup, thanks [lotharsm](https://github.com/fatalhalt/gentoox/commit/1da62330b78d462b885e16d038b8439bd2144fae)
  * all packages updated as of 5/11
  * as always, LiveCD credentials are **gentoox/gentoox** for user and password, automatic partitioning recommended, test and get familiar with install.sh in virtualbox, do not forget to run **emerge --sync** after the install
* 2020.05.01 Release
  * add support for NVMe drives to install.sh installation script
  * enable flatpak support in KDE Discover
  * update all packages to May 1 2020
* 2020.04.25 Release -- initial release

## Download
http://gentoox.cryptohash.nl/

![kicker](https://raw.githubusercontent.com/fatalhalt/gentoox/master/kicker.jpg?raw=true)

![dolphin](https://raw.githubusercontent.com/fatalhalt/gentoox/master/dolphin.jpg?raw=true)

The ISO weighs around 4GB and following settings were used to build it:
## CFLAGS
```sh
source make.conf.lto
COMMON_FLAGS="-O3 -march=sandybridge -mtune=sandybridge -mfpmath=both -pipe -funroll-loops -fgraphite-identity -floop-nest-optimize -fdevirtualize-at-ltrans -fipa-pta -fno-semantic-interposition -flto=12 -fuse-linker-plugin -malign-data=cacheline -Wl,--hash-style=gnu"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
RUSTFLAGS="-C target-cpu=sandybridge"
CPU_FLAGS_X86="aes mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
```
## USE flags
```sh
USE="-bindist elogind -consolekit -systemd udev dbus X wayland gles vulkan plymouth pulseaudio ffmpeg ipv6 -webkit infinality"
```
## FAQ
> (Q) **what are the user/password credentials for LiveCD?**

**gentoox** and **gentoox**
> (Q) **what is the main motivation behind GentooX?**

I found it rather tedious to setup a clean Gentoo install and LTO all the packages, not only gcc has to be rebuilt to support graphite, but then your entire stage3 install needs to be recompiled, not to mention already installed software. GentooX aims to provide pre-compiled and LTOed packages from the get go with easy installation and convenient LiveCD. Since GentooX mandates AVX support, this allows further optimizations to all packages.
> (Q) **how can I start KDE?**

login to tty1 using gentoox/gentoox and type 'startx'
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
emerge -avuDN --with-bdeps=y --exclude gentoo-sources @world
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
* a "hwclock: settimeofday() failed: Invalid argument" message may be seen during bootup: run
```sh
rc-update delete hwclock boot
```
* 'sudo su' by default grants root without asking for password, to be decided, can be disabled by editing sudoers
 
