#!/usr/bin/env bash

if [ -z "$1" ]; then
    image=$(zenity --file-selection --title="Open File" --file-filter="*.jpg *.jpeg *.png *.webp *.bmp *.jfif *.tiff *.avif *.heic *.heif")
else
    image="$1"
fi

[ -z "$image" ] && exit 1

ext=${image##*.}
image_copied="$HOME/.config/hypr/wallpaper.$ext"

cp -f "$image" "$image_copied" || exit 1

hyprctl hyprpaper reload ,"$image_copied" || exit 1
echo "preload = $image_copied" >"$HOME/.config/hypr/hyprpaper.conf"
echo "wallpaper = , $image_copied" >>"$HOME/.config/hypr/hyprpaper.conf"

notify-send "Wallpaper Changed" "$image"

notify-send "Extracting colors from wallpaper" "This may take a few seconds..."
change-colortheme.py -i "$image_copied" || exit 1
