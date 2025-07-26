#!/bin/sh

[ -z $SMB_CREDENTIALS ] && SMB_CREDENTIALS="$HOME/.smbcredentials"
[ ! -f $SMB_CREDENTIALS ] && exit 1

[ -z $SMB_HOST ] && SMB_HOST="10.8.0.1"
[ -z $SMB_DIR ] && SMB_DIR="share"
[ -z $SMB_MOUNT_POINT ] && SMB_MOUNT_POINT="/mnt/smb"
[ -z $SMB_UID ] && SMB_UID=$(id -u)
[ -z $SMB_GID ] && SMB_GID=$(id -g)

[ ! -d "$SMB_MOUNT_POINT" ] && sudo mkdir -p "$SMB_MOUNT_POINT"

sudo mount -t cifs //$SMB_HOST/$SMB_DIR "$SMB_MOUNT_POINT" -o credentials=$SMB_CREDENTIALS,uid=$SMB_UID,gid=$SMB_GID

if [ $? -eq 0 ]; then
    echo "Mounted $SMB_HOST/$SMB_DIR at $SMB_MOUNT_POINT"
else
    echo "Failed to mount $SMB_HOST/$SMB_DIR at $SMB_MOUNT_POINT"
    exit 1
fi
