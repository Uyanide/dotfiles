###
 # @Author: Uyanide pywang0608@foxmail.com
 # @Date: 2025-06-14 20:23:25
 # @LastEditTime: 2025-08-03 00:33:45
 # @Description: Change the desktop wallpaper and update colortheme
###
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

notify-send "Wallpaper Changed" "$image"

change-colortheme.py "#$(
    notify-send "Extracting color from wallpaper" "This may take a few seconds..."
    extract-color.py "$image"
)"