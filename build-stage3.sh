#!/bin/bash

version_stamp="$(date +%Y%m%d).graphite"

if [[ ! -f .catalyst-prep-done ]]; then
  builddate=$(wget --quiet -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/ | sed -nr "s/.*href=\"stage3-amd64-([0-9].*).tar.xz\">.*/\1/p")
  if [[ ! -f "stage3-amd64-$builddate.tar.xz" ]]; then
    wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-$builddate.tar.xz
  fi

  (git clone https://github.com/gentoo/releng.git; cd releng; patch -p1 < ../0001-releng-gcc-add-graphite-support.patch)

  mkdir -p /var/tmp/catalyst/builds/default
  cp -v "stage3-amd64-$builddate.tar.xz" /var/tmp/catalyst/builds/default/stage3-amd64-latest.tar.xz
  emerge --sync
  catalyst -s latest
  touch .catalyst-prep-done
fi

cp -v releng/releases/weekly/specs/amd64/stage{1,2,3}.spec .

sed -i "s/version_stamp: latest/version_stamp: $version_stamp/" stage1.spec
sed -i "s#@REPO_DIR@#$(pwd)/releng#g" stage1.spec
sed -i "s/version_stamp: latest/version_stamp: $version_stamp/" stage2.spec
sed -i "s/source_subpath: default\/stage1-amd64-latest/source_subpath: default\/stage1-amd64-$version_stamp/" stage2.spec
sed -i "s#@REPO_DIR@#$(pwd)/releng#g" stage2.spec
sed -i "s/version_stamp: latest/version_stamp: $version_stamp/" stage3.spec
sed -i "s/source_subpath: default\/stage2-amd64-latest/source_subpath: default\/stage2-amd64-$version_stamp/" stage3.spec
sed -i "s#@REPO_DIR@#$(pwd)/releng#g" stage3.spec

catalyst -f stage1.spec
catalyst -f stage2.spec
catalyst -f stage3.spec

cp -v /var/tmp/catalyst/builds/default/stage3-amd64-$version_stamp.tar.xz .

