#!/bin/sh

find /lib/modules/$(uname -r)/{extra,misc}/ -name "*.ko" -exec /usr/src/linux/scripts/sign-file sha256 /usr/src/uefi/MOK.priv /usr/src/uefi/MOK.pem {} \;
exit 0
