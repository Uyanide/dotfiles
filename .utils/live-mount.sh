#!/bin/sh

[ -z "$MOUNT_DIR" ] && MOUNT_DIR="/mnt"

if ! umount "$MOUNT_DIR" -R; then
    echo "Failed to unmount $MOUNT_DIR."
    exit 1
fi

[ -z "$DEVICE" ] && DEVICE="/dev/sda"
[ -z "$START_PART" ] && START_PART="1"

efi_part="${DEVICE}p${START_PART}"

START_PART=$(expr $START_PART + 1)
boot_part="${DEVICE}p${START_PART}"

START_PART=$(expr $START_PART + 1)
btrfs_part="${DEVICE}p${START_PART}"

mount "$btrfs_part" -o subvol=@ "$MOUNT_DIR"
mount "$btrfs_part" -o subvol=@home "$MOUNT_DIR"/home
mount "$btrfs_part" -o subvol=@log"$MOUNT_DIR"/var/log
mount "$btrfs_part" -o subvol=@cache "$MOUNT_DIR"/var/cache
mount "$btrfs_part" -o subvol=@tmp "$MOUNT_DIR"/tmp
# mount "$btrfs_part" -o subvol=@swap "$MOUNT_DIR"/swap
mount "$boot_part" "$MOUNT_DIR"/boot
mount "$efi_part" "$MOUNT_DIR"/boot/efi
swapon "$MOUNT_DIR"/swap/swapfile