#!/bin/fish

# if the path is given as an argument, use that
if test (count $argv) -eq 1
    set image $argv[1]
else
    set image (zenity --file-selection --title="Open File" --file-filter="*.jpg *.jpeg *.png")
end

if test -z "$image"
    exit 1
end
if not test -f "$image"
    notify-send "Error" "Selected file does not exist."
    exit 1
end
if string match -q "* *" "$image"
    notify-send "Error" "Selected file path contains white spaces, please select a file without white spaces."
    exit 1
end

hyprctl hyprpaper reload ,"$image"
echo "preload = $image" > ~/.config/hypr/hyprpaper.conf
echo "wallpaper = , $image" >> ~/.config/hypr/hyprpaper.conf

notify-send "Wallpaper Changed" "Wallpaper changed to \"$image\" successfully."