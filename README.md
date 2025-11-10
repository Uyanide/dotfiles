## How it looks like...

<details>
<summary>Hyprland & Waybar & Eww</summary>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop.jpg?raw=true"/>
</figure>

</details>

<details>

<summary>Niri & Quickshell</summary>

https://github.com/user-attachments/assets/7e2db305-58bc-4b3d-9c65-7dc0461aead7

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop-alt.jpg?raw=true"/>
</figure>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/backdrop.jpg?raw=true"/>
</figure>

</details>

<details>
<summary>Grub menu</summary>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/grub.jpg?raw=true"/>
</figure>

</details>

## Setup Overview

- OS: Archlinux
- WM: Hyprland | **Niri**
- Bar: Waybar | **Quickshell**
- Shell: Fish
- Prompt: Oh My Posh
- Terminal: **Kitty** & Ghostty
- Power Menu: Wlogout
- Colorscheme: Catppuccin Mocha
- App Launcher: **Rofi** | fuzzel
- Desktop Widgets: Eww | **Quickshell**
- Wallpaper Daemon: Swww
- Notification Daemon: Mako | **Quickshell**

(**bold**: currently preferred)

## Hyprland & friends

Based on an old version of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) but without ags, quickshell, eww and tons of other stuff.

## Niri

Ported from Hyprland, and shares some of the desktop components such as hyprlock & hypridle, but uses quickshell as bar / desktop widgets / notification daemon / ...

## Quickshell

Not based on, but heavily depends on many modules from [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell). A thousand thanks to their great work.

This setup is currently only adapted for Niri.

## Eww

- `main`, main dashboard, modified from [syndrizzle/hotfiles](https://github.com/syndrizzle/hotfiles/tree/bspwm) but without notification center.
- `lyrics`, scrolling lyrics player, depends on [a small utility](https://github.com/Uyanide/Spotify_Lyrics) from myself <small>(which also happens to be my frist Golang program :D)</small>.
- `lyrics-single`, similar to `lyrics`, but only with a single line and can be easily embeded into the status bar.

## Swww

The wallpaper will be automatically blurred when there is a window in focus, which is implemented in the [wallpaper-daemon](https://github.com/Uyanide/dotfiles/blob/main/scripts/wallpaper-daemon) script.

This feature is only enabled in Niri. Swww also manages wallpapers of the Hyprland setup, yet only in the regular way.

## Wallpaper & Colortheme

The most suitable primary color (or so-called flavor) will be chosen from the [Catppuccin Mocha](https://catppuccin.com/palette/) palette and applied to various apps automatically after changing wallpaper. See also:

- [wallpaper-carousel](https://github.com/Uyanide/Wallpaper_Carousel) to select wallpaper, which implements an Image Carousel with Qt Widgets.
- [backgrounds collection](https://github.com/Uyanide/backgrounds) for personal use.

## Rofi

Based on [codeopshq/dotfiles](https://github.com/codeopshq/dotfiles), also serves as the clipboard history browser and emoji picker.

## Grub theme

Based on [vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes) with an [illustration from 紺屋鴉江](https://www.pixiv.net/artworks/119683453).

## MPV

Based on [noelsimbolon/mpv-config](https://github.com/noelsimbolon/mpv-config.git).

## Fonts

including:

- Maple Mono NF CN
- MesloLGM Nerd Font (& Mono)
- WenQuanYi Micro Hei
- Sour Gummy
- Noto Sans
- ...
