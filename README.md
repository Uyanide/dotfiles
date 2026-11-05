<img src="https://raw.githubusercontent.com/Uyanide/dotfiles/refs/heads/main/assets/works-on-my-machines.png" alt="Works on my machine(s)" width="200" />


## Setup Overview

> [!NOTE]
>
> See also [config-stow](./config-stow) for the list of stow packages.

- OS: Archlinux | Debian
- WM: Hyprland | **Niri**
- Bar: ~~Waybar~~ | ~~Quickshell~~ | Noctalia
- Shell: (bash & fish) | **Zsh**
- Prompt: Oh My Posh | **Starship**
- Terminal: **Kitty** | WezTerm | Ghostty
- Power Menu: ~~Wlogout~~ | ~~Quickshell~~ | Noctalia
- Colorscheme: Catppuccin Mocha
- App Launcher: ~~Rofi~~ | ~~Fuzzel~~ | ~~vicinae~~ | Noctalia
- Desktop Widgets: ~~Eww~~ | ~~Quickshell~~ | Noctalia
- Wallpaper Daemon: ~~Awww~~ | ~~Quickshell~~ | Parra
- Notification Daemon: ~~Mako~~ | ~~Quickshell~~ | Noctalia

marked with:

- **bold**: currently preferred
- ~~strikethrough~~: previously used but not anymore, moved to `legacy` folder

## Wallpaper & Colortheme

- [WallReel](https://github.com/Uyanide/WallReel): image carousel implemented with QtQuick to browse and set wallpapers.
- [Parra](https://github.com/Uyanide/Parra): wallpaper daemon that supports compositor-driven effects.
- [change-colortheme](./config/scripts/.local/scripts/change-colortheme): script that extract colors from the current wallpaper and generate a catppuccin color scheme accordingly.
- [backgrounds](https://github.com/Uyanide/backgrounds) collection for personal use (mostly waifus).

## Grub theme

Based on [vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes) with an [illustration from 紺屋](https://www.pixiv.net/artworks/119683453).

## Fonts

See [fontconfig.md](https://github.com/Uyanide/dotfiles/blob/main/memo/fontconfig.md).

---

## Legacy setups

<details>
<summary>Niri & Quickshell</summary>

## How it ~~looks~~ looked like...

https://github.com/user-attachments/assets/2550607a-48ea-4662-98ba-d26722b26b1b

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop-alt.webp?raw=true"/>
</figure>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/backdrop.webp?raw=true"/>
</figure>

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/grub.jpg?raw=true"/>
</figure>

## Quickshell

Not based on, but heavily depends on many modules from (an old version of) [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell). A thousand thanks to their great work.

This setup is currently only adapted for Niri.

</details>

<details>
<summary>Hyprland & Eww</summary>

## How it ~~looks~~ looked like...

<figure>
    <img src="https://github.com/Uyanide/backgrounds/blob/master/screenshots/desktop.jpg?raw=true"/>
</figure>

## Hyprland & friends

Based on an old version of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) but without ags, quickshell, eww and tons of other stuff.

## Eww

- `main`, main dashboard, modified from [syndrizzle/hotfiles](https://github.com/syndrizzle/hotfiles/tree/bspwm) but without notification center.
- `lyrics`, scrolling lyrics player, depends on [a small utility](https://github.com/Uyanide/Spotify_Lyrics) from myself <small>(which also happens to be my frist Golang program :D)</small>.
- `lyrics-single`, similar to `lyrics`, but only with a single line and can be easily embeded into the status bar.

## Swww

The wallpaper will be automatically blurred when there is a window in focus, which is implemented in the [wallpaper-daemon](https://github.com/Uyanide/dotfiles/blob/main/.scripts/wallpaper-daemon) script.

This feature is only enabled in Niri. Swww also manages wallpapers of the Hyprland setup, yet only in the regular way.

## Wallpaper & Colortheme

The most suitable primary color (or so-called flavor) will be chosen from the [Catppuccin Mocha](https://catppuccin.com/palette/) palette and applied to various apps automatically after changing wallpaper. And also:

- [wallpaper-chooser](https://github.com/Uyanide/Wallpaper_Chooser) to select wallpaper, which implements an Image Carousel with Qt Widgets.
- [backgrounds collection](https://github.com/Uyanide/backgrounds) for personal use.

## Rofi

Based on [codeopshq/dotfiles](https://github.com/codeopshq/dotfiles), also serves as the clipboard history browser and emoji picker.

</details>
