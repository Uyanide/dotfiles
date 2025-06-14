#!/bin/sh

device="/dev/nvme0n1"
efi_part="${device}p3"
boot_part="${device}p4"
btrfs_part="${device}p5"

umount /mnt -R

mount $btrfs_part -o subvol=@ /mnt
mount $btrfs_part -o subvol=@home /mnt/home
mount $btrfs_part -o subvol=@log /mnt/var/log
mount $btrfs_part -o subvol=@cache /mnt/var/cache
mount $btrfs_part -o subvol=@tmp /mnt/tmp
mount $btrfs_part -o subvol=@swap /mnt/swap
mount $boot_part /mnt/boot
mount $efi_part /mnt/boot/efi
swapon /mnt/swap/swapfile