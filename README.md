## Screenshots

- Hyprland & Waybar & Eww:

    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop.jpg?raw=true"/>

- Niri & Quickshell

    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop-alt.jpg?raw=true"/>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/backdrop.jpg?raw=true"/>

- Grub menu:

    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/grub.jpg?raw=true"/>

## Setup Overview

- OS: Archlinux
- WM: Hyprland | **Niri**
- Bar: Waybar | **Quickshell**
- Shell: Fish
- Prompt: Oh My Posh
- Terminal: **Kitty** & Ghostty
- Colorscheme: Catppuccin Mocha
- App Launcher: Rofi
- Logout Screen: Wlogout
- Desktop Widgets: Eww | **Quickshell**
- Wallpaper Daemon: Swww
- Notification Daemon: Mako | **Quickshell**

(**bold**: I currently prefer)

## Hyprland & friends

Based on an old version of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) but without ags, quickshell, eww and tons of other stuff.

## Niri

Ported from Hyprland, and shares some of the desktop components such as hyprlock & hypridle, but uses quickshell as bar / desktop widgets / notification daemon / ...

## Quickshell

Not based on, but heavily depends on many modules from [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell). A thousand thanks to their great work.

This setup is currently only adapted for Niri.

## Eww

- `main`, main dashboard, modified from [syndrizzle/hotfiles](https://github.com/syndrizzle/hotfiles/tree/bspwm) but without notification center.
- `lyrics`, scrolling lyrics player, depends on [a small utility](https://github.com/Uyanide/spotify-lyrics) from myself <small>(which also happens to be my frist Golang program :D)</small>.
- `lyrics-single`, similar to `lyrics`, but only with a single line and can be easily embeded into the status bar.

## Swww

The wallpaper will be automatically blurred when there are windows in focus. And the backdrop (overview) also has a blurred version of the wallpaper applied to its background. These are implemented in [wallpaper-daemon](https://github.com/Uyanide/dotfiles/blob/main/.scripts/wallpaper-daemon).

This feature is only enabled in Niri. Swww also manages the wallpaper of the Hyprland setup, yet only in the regular way.

## Rofi

Based on [codeopshq/dotfiles](https://github.com/codeopshq/dotfiles), also serves as clipboard history browser and emoji picker.

## Grub theme

Based on [vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes) with [illustration from 紺屋鴉江](https://www.pixiv.net/artworks/119683453).

## MPV

Based on [noelsimbolon/mpv-config](https://github.com/noelsimbolon/mpv-config.git).

## Wallpaper(s)

See [backgrounds repo for personal usage](https://github.com/Uyanide/backgrounds).

## Fonts

including:

- Maple Mono NF CN
- MesloLGM Nerd Font (& Mono)
- WenQuanYi Micro Hei
- Sour Gummy
- Noto Sans
- ...
