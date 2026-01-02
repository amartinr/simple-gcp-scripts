#!/bin/bash
BP_DISK_DEV="/dev/disk/by-id/google-persistent-disk-1"
SWAP="${SWAP:-false}"  # Por defecto, sin swap

log() {
    echo "$1"
    logger -t disk-format "$1"
}

if [ ! -L "${BP_DISK_DEV}" ]; then
    log "ERROR: Disk device not found"
    exit 1
fi

DISK_DEV=$(readlink -f "${BP_DISK_DEV}")
PARTITION_COUNT=$(parted -s "${DISK_DEV}" print 2>/dev/null | grep -c "^ [0-9]")

if [ "$PARTITION_COUNT" -ne 0 ]; then
    log "Disk is already partitioned."
else

    log "Initializing disk (swap: ${SWAP})..."

    parted -s "${DISK_DEV}" mklabel gpt

    if [ "${SWAP}" = "true" ] || [ "${SWAP}" = "1" ]; then
        DISK_SIZE=$(parted -s "${DISK_DEV}" unit GiB print free | grep "^Disk" | awk '{print $3}' | sed 's/GiB//')
        END_POS=$(awk "BEGIN {printf \"%.0f\", $DISK_SIZE - 8}")

        parted -s "${DISK_DEV}" mkpart primary ext4 0% ${END_POS}GiB
        parted -s "${DISK_DEV}" mkpart primary linux-swap ${END_POS}GiB 100%

        udevadm settle
        log "Formatting swap partition..."
        mkswap "${DISK_DEV}2"
    else
        parted -s "${DISK_DEV}" mkpart primary ext4 0% 100%
    fi

    udevadm settle

    log "Formatting data partition..."
    mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "${DISK_DEV}1"

    log "Disk initialization complete."
fi
