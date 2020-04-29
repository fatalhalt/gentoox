# GentooX

an -O3, AVX, Graphite, and LTO optimized x86_64 LiveCD Gentoo distribution with installer. Aimed at gamers and benchmarking.

Comes with simple interactive *install.sh* script, supports BIOS and UEFI x86_64 systems, at minimum requires AVX capable CPUs released since 2011 such as Intel Sandybridge or AMD Bulldozer, among KDE, it includes Steam flatpak and phoronix-suite out-of-the-box.

* based on Gentoo's ~amd64
* OpenRC init system
* latest KDE Desktop Environment with custom GentooX theme, global menus enabled by default, latte dock
* Firefox global menu support patched in, OpenGL acceleration enabled by default, PGO build
* gentoLTO overly
* BTRFS used by default with lzo compression and snapshot setup modeled after openSUSE
* phoronix-suite available out-of-the-box for benchmarking purposes
* Steam installed out-of-the-box with necessary lib32 dependencies and fsync Linux kernel patched in
* flatpak is included, easily install VSCode or Discord in sandboxed environment
* ZFS support, kernel patched to export FPU functions
* Linux 5.6.7 kernel built with 1000Hz -03 Sandybridge and aufs, ClearLinux, fsync, unprivileged CLONE_NEWUSER, and IOMMU missing ACS capabilities overrides

The ISO weighs around 4GB and following settings were used to build it:
## CFLAGS
```sh
COMMON_FLAGS="-O3 -march=sandybridge -mtune=sandybridge -mfpmath=both -pipe -funroll-loops -fgraphite-identity -floop-nest-optimize -fdevirtualize-at-ltrans -fipa-pta -fno-semantic-interposition -flto=12 -fuse-linker-plugin -malign-data=cacheline -Wl,--hash-style=gnu"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
RUSTFLAGS="-C target-cpu=sandybridge"
CPU_FLAGS_X86="aes avx mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
MAKEOPTS="-j12"
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

> **(Q) how can I start KDE?**

login to tty1 using gentoox/gentoox and type 'startx'
> **(Q) what are the minimum requirements?**

any AVX capable CPUs released since 2011 such as Intel Sandybridge or AMD Bulldozer, 4GB of RAM (mostly due to LiveCD being 4GB squashfs file), and 16GB of disk space for root partition where openSUSE's style BTRFS will be setup and 128MB boot partition
> (Q) **how can GentooX be installed?**

boot LiveCD, login with gentoox/gentoox credentails, sudo su, and run ./install.sh, the install script is interactive, BIOS and UEFI systems are supported
> (Q) **how does the installation work?**

The installation carried by install.sh is very simple, besides interactive partitioning the setup extracts 4GB image.squashfs into root partition that ends up taking 13GB of space which includes all the pre-compiled software such as KDE and Steam.
 -SDDM can be enabled this and that, otherwise 'startx' is used by default
 -Theme is not applying correctly? make sure to logout/login when after initial 'startx' startup in LiveCD or after installation
 -sudo su by default grants root without asking for password, to be decided
 
 > (Q) **why GentooX name?**
 
 I couldn't come up with anything better at time, I know there's a Gentoo distribution aimed at original XBOX named 'gentoox'. My distro uses capital X at the end for now (Gentoo**X**).

## Known issues
a "hwclock: settimeofday() failed: Invalid argument" message can be seen during bootup, I believe this is upstream Gentoo issue.
 
