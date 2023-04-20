#!/bin/bash
BP_DISK_DEV="/dev/disk/by-id/google-persistent-disk-1"
if [ -L "${BP_DISK_DEV}" ]; then
    mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $BP_DISK_DEV
    mount $BP_DISK_DEV /mnt
    mkdir /mnt/{hub,models}
    chown 1000.1001 /mnt/hub
    chown 1000.1001 /mnt/models
#    mount -o bind /mnt/models /home/amartinr/llama.cpp/models
fi
exit 0

export DEBIAN_FRONTEND=noninteractive
# disable generation of man pages
cat << EOF > /etc/dpkg/dpkg.cfg.d/01_nodoc
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
EOF

# replace man with dman
cat << EOF > /etc/skel/.bash_aliases
alias man='dman'
EOF

# initialize second disk
#mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-lora-data-1

# swap user directories to second disk
#mount /dev/disk/by-id/google-persistent-disk-1 /mnt
#mv /home/* /mnt && sync
#umount /mnt
#mount /dev/disk/by-id/google-persistent-disk-1 /home

#sed -ri "s/^deb-src(.*)/#deb-src\1/;s/bullseye(-updates|-backports)?\ main/bullseye\1 main contrib non-free/" /etc/apt/sources.list
#apt update && apt install -y software-properties-common
#apt-add-repository contrib && apt-add-repository non-free
#apt update && apt install --no-install-recommends -y curl bash-completion debian-goodies git git-lfs python3-pip
