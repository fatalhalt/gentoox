#!/bin/bash

emerge -u catalyst pixz
version_stamp="$(date +%Y%m%d).graphite"

if [[ ! -f .catalyst-accept-keywords ]]; then
  echo -e '\nexport ACCEPT_KEYWORDS="~amd64"' >> /etc/catalyst/catalystrc
  touch .catalyst-accept-keywords
fi

if [[ ! -f .catalyst-prep-done ]]; then
  builddate=$(wget --quiet -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/ | sed -nr "s/.*href=\"stage3-amd64-openrc-([0-9].*).tar.xz\">.*/\1/p")
  if [[ ! -f "stage3-amd64-openrc-$builddate.tar.xz" ]]; then
    wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-$builddate.tar.xz
  fi

  (git clone https://github.com/gentoo/releng.git; cd releng; patch -p1 < ../0001-releng-gcc-add-graphite-support.patch)

  mkdir -p /var/tmp/catalyst/builds/default
  mkdir -p /var/tmp/catalyst/snapshot_cache/latest
  cp -v "stage3-amd64-openrc-$builddate.tar.xz" /var/tmp/catalyst/builds/default/stage3-amd64-openrc-latest.tar.xz
  emerge --sync
  catalyst -s latest
  touch .catalyst-prep-done
fi

cp -v releng/releases/specs/amd64/stage{1,2,3}-openrc.spec .

sed -i "s/version_stamp: openrc-@TIMESTAMP@/version_stamp: $version_stamp/" stage1-openrc.spec
sed -i "s/snapshot: @TIMESTAMP@/snapshot: latest/" stage1-openrc.spec
sed -i "s#@REPO_DIR@#$(pwd)/releng#g" stage1-openrc.spec
sed -i "s/version_stamp: openrc-@TIMESTAMP@/version_stamp: $version_stamp/" stage2-openrc.spec
sed -i "s/snapshot: @TIMESTAMP@/snapshot: latest/" stage2-openrc.spec
sed -i "s/source_subpath: default\/stage1-amd64-openrc-@TIMESTAMP@/source_subpath: default\/stage1-amd64-$version_stamp/" stage2-openrc.spec
sed -i "s#@REPO_DIR@#$(pwd)/releng#g" stage2-openrc.spec
sed -i "s/version_stamp: openrc-@TIMESTAMP@/version_stamp: $version_stamp/" stage3-openrc.spec
sed -i "s/snapshot: @TIMESTAMP@/snapshot: latest/" stage3-openrc.spec
sed -i "s/source_subpath: default\/stage2-amd64-openrc-@TIMESTAMP@/source_subpath: default\/stage2-amd64-$version_stamp/" stage3-openrc.spec
sed -i "s#@REPO_DIR@#$(pwd)/releng#g" stage3-openrc.spec

catalyst -f stage1-openrc.spec
catalyst -f stage2-openrc.spec
catalyst -f stage3-openrc.spec

cp -v /var/tmp/catalyst/builds/default/stage3-amd64-$version_stamp.tar.xz .

