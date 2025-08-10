#!/bin/sh

path="$(dirname "$(realpath "$0")")"

"$path/issu.sh" && {
    echo "Do not run this script in sudo mode."
    exit 1
}

[ -z "$1" ] && echo "Usage: $0 <VHDX_PATH>" && exit 1

vhdx_path="$1"

[ -z "$2" ] && mount_point="/mnt/wsl" || mount_point="$2"

[ -d "$mount_point" ] || sudo mkdir -p "$mount_point"

username=$(whoami)

sudo chown "$username:$username" "$mount_point"

export LIBGUESTFS_BACKEND=direct

# replay log
# qemu-img check -r all "$VHDX_PATH" || {
#     echo "Failed to check VHDX file."
#     exit 1
# }

guestmount --add "$vhdx_path" --inspector --ro "$mount_point" || {
    echo "Failed to mount VHDX file."
    exit 1
}

echo "Successfully mounted $vhdx_path to $mount_point"
