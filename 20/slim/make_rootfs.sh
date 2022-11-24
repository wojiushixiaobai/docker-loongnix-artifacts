#!/bin/bash

DISTRO=loongnix
RELEASE=DaoXiangHu-stable
MIRROR_ADDRESS=http://pkg.loongnix.cn/loongnix/

ROOTFS=rootfs

## 检测 debootstrap 命令存在
if ! $(command -v debootstrap > /dev/null); then
	echo "command debootstrap not found"
	exit 1
fi

## 检测 xz 命令存在
if ! $(command -v xz > /dev/null); then
	echo "command xz not found"
	exit 1
fi

WKDIR=`mktemp -d`
mkdir -pv $WKDIR/$ROOTFS
cp .slimify-includes $WKDIR/.slimify-includes
cp .slimify-excludes $WKDIR/.slimify-excludes
pushd $WKDIR

if [ ! -f /usr/share/debootstrap/scripts/$RELEASE ]; then
	ln -s /usr/share/debootstrap/scripts/stable /usr/share/debootstrap/scripts/$RELEASE
fi

debootstrap --no-check-gpg --variant=minbase --components=main,non-free,contrib --arch=loongarch64 --foreign $RELEASE $ROOTFS $MIRROR_ADDRESS

chroot ${ROOTFS} debootstrap/debootstrap --second-stage

# slimify
slimIncludes=( $(sed '/^#/d;/^$/d' .slimify-includes | sort -u) )
slimExcludes=( $(sed '/^#/d;/^$/d' .slimify-excludes | sort -u) )

findMatchIncludes=()
for slimInclude in "${slimIncludes[@]}"; do
        {
                [ "${#findMatchIncludes[@]}" -eq 0 ] || findMatchIncludes+=( '-o' )
                findMatchIncludes+=( -path "$slimInclude" )
        }
done
findMatchIncludes=( '(' "${findMatchIncludes[@]}" ')' )

for slimExclude in "${slimExcludes[@]}"; do
        {
                chroot $ROOTFS \
                        find "$(dirname "$slimExclude")" \
                        -depth -mindepth 1 \
                        -not \( -type d -o -type l \) \
                        -not "${findMatchIncludes[@]}" \
                        -exec rm -f '{}' ';'
        }
done

while [ "$(
        chroot $ROOTFS \
                find "$(dirname "$slimExclude")" \
                -depth -mindepth 1 \( -empty -o -xtype l \) \
                -exec rm -rf '{}' ';' -printf '.' \
                | wc -c
        )" -gt 0 ]; do true; done


tar -cJf rootfs.tar.xz -C $ROOTFS .
popd

if [ -f rootfs.tar.xz ]; then
    rm -f rootfs.tar.xz
fi

mv $WKDIR/rootfs.tar.xz .
sha256sum rootfs.tar.xz | awk '{ print $1 }' > rootfs.tar.xz.sha256
rm -rf $WKDIR
