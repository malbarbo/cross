set -ex

main() {
    local arch=$1 \
          suite=$2 \
          mirror=$3 \
          td=$(mktemp -d)
    local dest=$td/newroot

    local dependencies=(
        cpio
        curl
        debian-archive-keyring
        debootstrap
        qemu-user-static
    )

    apt-get update
    local purge_list=()
    for dep in ${dependencies[@]}; do
        if ! dpkg -L $dep; then
            apt-get install --no-install-recommends -y $dep
            purge_list+=( $dep )
        fi
    done

    mkdir -p $dest
    pushd $td

    qemu-debootstrap \
        --arch=$arch \
        --variant=minbase \
        --include="linux-image-$arch,systemd-sysv,openssh-server" \
        $suite \
        $dest \
        $mirror || true

    # HACK
    rm -f $dest/var/lib/dpkg/status
    mv $dest/bin/mount $td
    cp $dest/bin/true $dest/bin/mount
    # ln -s /proc $dest/proc
    chroot $dest /debootstrap/debootstrap --second-stage

    # ssh
    chroot $dest adduser --disabled-password --gecos "" cross
    echo "cross:cross" | chroot $dest chpasswd
    echo "root:root" | chroot $dest chpasswd

    # fstab
    # /target will be auto mounted in qemu /target using virtfs
    mkdir $dest/target
    cat <<EOF > $dest/init
#!/bin/sh
modprobe virtio_pci
modprobe 9pnet_virtio
exec /sbin/init
EOF
    chmod +x $dest/init

    cat <<EOF > $dest/etc/fstab
target /target 9p trans=virtio,version=9p2000.L,posixacl,cache=loose 0 0
EOF


    # networking
    chroot $dest systemctl enable systemd-networkd

    cat <<EOF > $dest/etc/hostname
qemu
EOF

    cat <<EOF > $dest/etc/hosts
127.0.0.1 localhost
EOF

    cat <<EOF > $dest/etc/systemd/network/80-dhcp.network
[Match]
Name=*
[Network]
DHCP=v4
EOF

    # return original files
    # rm -f $dest/proc $dest/bin/mount
    mv -f $td/mount $dest/bin/mount
    # mv $td/proc $dest/proc

    # kernel, ramdisk and boot loader
    mkdir /qemu/
    curl -LO https://github.com/qemu/qemu/raw/master/pc-bios/s390-ccw.img
    mv s390-ccw.img /qemu

    cp -f $dest/vmlinuz /qemu/vmlinuz

    # remove some stuff to reduce the ramdisk size
    # TODO: use qemu-debootstrap --exclude=...
    rm -rf $dest/usr/lib/*-linux-*/gconv \
           $dest/usr/lib/*-linux-*/perl-base \
           $dest/usr/share/ \
           $dest/boot \
           $dest/var/cache \
           $dest/var/lib/apt \
           $dest/var/lib/dpkg \
           $dest/var/log/*

    # umount $dest/proc
    # umount $dest/sys

    cd $dest
    find . -print0 | cpio --null -ov --format=newc | gzip > /qemu/initrd.img
    cd -

    # clean up
    apt-get purge --auto-remove -y ${purge_list[@]}
    popd

    rm -rf $td
}

main "${@}"
