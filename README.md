<img src="https://raw.githubusercontent.com/Uyanide/dotfiles/refs/heads/main/assets/works-on-my-machines.png" alt="Works on my machine(s)" width="200" />

## How it looks like...

<details>
<summary>Hyprland & Waybar & Eww</summary>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop.jpg?raw=true"/>
</figure>

</details>

<details>

<summary>Niri & Quickshell</summary>

https://github.com/user-attachments/assets/af29bcac-7207-4f23-88bb-d8c5d447776a

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop-alt.webp?raw=true"/>
</figure>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/backdrop.webp?raw=true"/>
</figure>

</details>

<details>
<summary>Grub menu</summary>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/grub.jpg?raw=true"/>
</figure>

</details>

## Setup Overview

> [!NOTE]
>
> See also [config-stow](./config-stow) for the list of stow packages.

- OS: **Archlinux**
- WM: Hyprland | **Niri**
- Bar: Waybar | **Quickshell**
- Shell: **Fish**
- Prompt: **Oh My Posh**
- Terminal: **Kitty** & (**WezTerm** | Ghostty)
- Power Menu: **Wlogout** & Quickshell
- Colorscheme: **Catppuccin Mocha**
- App Launcher: **Rofi** | Fuzzel
- Desktop Widgets: Eww | **Quickshell**
- Wallpaper Daemon: Awww | **Quickshell**
- Notification Daemon: Mako | **Quickshell**

(**bold**: currently preferred)

## Hyprland & friends

Based on an old version of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) but without ags, quickshell, eww and tons of other stuff.

## Niri

Ported from Hyprland, and shares some desktop components such as hyprlock & hypridle, but uses quickshell as bar / desktop widgets / notification daemon / ...

## Quickshell

Not based on, but heavily depends on many modules from (an old version of) [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell). A thousand thanks to their great work.

This setup is currently only adapted for Niri.

## Eww

- `main`, main dashboard, modified from [syndrizzle/hotfiles](https://github.com/syndrizzle/hotfiles/tree/bspwm) but without notification center.
- `lyrics`, scrolling lyrics player, depends on [a small utility](https://github.com/Uyanide/Spotify_Lyrics) from myself <small>(which also happens to be my frist Golang program :D)</small>.
- `lyrics-single`, similar to `lyrics`, but only with a single line and can be easily embeded into the status bar.

## Wallpaper & Colortheme

- [WallReel](https://github.com/Uyanide/WallReel): an Image Carousel implemented with QtQuick to browse and set wallpapers from.
- [change-colortheme](./config/scripts/.local/scripts/change-colortheme): script that extract colors from the current wallpaper and generate a catppuccin color scheme accordingly.
- [backgrounds](https://github.com/Uyanide/backgrounds) collection for personal use (mostly waifus).

## Rofi

Based on [codeopshq/dotfiles](https://github.com/codeopshq/dotfiles), also serves as the clipboard history browser and emoji picker.

## Grub theme

Based on [vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes) with an [illustration from 紺屋](https://www.pixiv.net/artworks/119683453).

## Fonts

See [fontconfig.md](https://github.com/Uyanide/dotfiles/blob/main/memo/fontconfig.md).
