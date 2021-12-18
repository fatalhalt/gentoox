#! /bin/sh

MODSECKEY=$1
MODPUBKEY=$2
moddir=$3

modules=$(find "$moddir" -type f -name '*.ko')

NPROC=$(nproc)
[ -z "$NPROC" ] && NPROC=1

echo "$modules" | xargs -r -n16 -P $NPROC sh -c "
for mod; do
    ./sign-file sha256 $MODSECKEY $MODPUBKEY \$mod
    rm -f \$mod.sig \$mod.dig
done
" DUMMYARG0   # xargs appends ARG1 ARG2..., which go into $mod in for loop.

exit 0
