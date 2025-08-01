#!/bin/env python3

'''
- kvantum:      kvantummanager --set catppuccin-mocha-"$flavor"

- nwg-look:     edit $HOME/.local/share/nwg-look/gsettings
                nwg-look -a

- eww:          edit $HOME/.config/eww/eww.scss
                eww reload

- hypr:         edit $HOME/.config/hypr/hyprland/colors.conf
                hyprctl reload

- rofi:         edit $HOME/.config/rofi/config.rasi

- waybar:       edit $HOME/.config/waybar/style.css
                waybar-toggle.sh

- ohmyposh:     edit $HOME/.config/posh_theme.omp.json

- fastfetch:    edit $HOME/.config/fish/post.d/fetch.fish

- mako:         edit $HOME/.config/mako/config
                makoctl reload

- yazi:         cp "$path"/../.yazi-themes/catppuccin-mocha-"$flavor".toml ~/.config/yazi/theme.toml

- wlogout:      edit $HOME/.config/wlogout/style.css
                edit $HOME/.config/wlogout/icons/*.svg
'''

import os
import sys
from pathlib import Path
import shutil

FLAVOR_NAME_PLACEHOLDER = "<FLAVOR_NAME>"
FLAVOR_HEX_PLACEHOLDER = "<FLAVOR_HEX>"

CATPPUCIN_MOCHA_PALETTE = {
    "rosewater": "f5e0dc",
    "flamingo": "f2cdcd",
    "pink": "f5c2e7",
    "mauve": "cba6f7",
    "red": "f38ba8",
    "maroon": "eba0ac",
    "peach": "fab387",
    "yellow": "f9e2af",
    "green": "a6e3a1",
    "teal": "94e2d5",
    "sky": "89dceb",
    "sapphire": "74c7ec",
    "blue": "89b4fa",
    "lavender": "b4befe"}

CURRENT_DIR = Path(__file__).resolve().parent.resolve()


def apply_flavor(file_path: Path, flavor: str):
    print(f"Applying flavor {flavor} to {file_path}")

    if not file_path.exists():
        print(f"File {file_path} does not exist.")
        raise FileNotFoundError(f"File {file_path} does not exist.")

    with file_path.open('r') as file:
        content = file.read()

    content = content.replace(FLAVOR_NAME_PLACEHOLDER, flavor)
    content = content.replace(FLAVOR_HEX_PLACEHOLDER, CATPPUCIN_MOCHA_PALETTE[flavor])

    with file_path.open('w') as file:
        file.write(content)


def copy_template(src: Path, dist_dir: Path | None) -> Path:
    if dist_dir is None:
        dist_dir = src.parent

    dist = dist_dir / src.name.removesuffix('.template')

    print(f"Copying {src} to {dist}")

    if not dist_dir.exists():
        print(f"Destination directory {dist_dir} does not exist.")
        raise FileNotFoundError(f"Destination directory {dist_dir} does not exist.")
    if not dist_dir.is_dir():
        print(f"Destination {dist_dir} is not a directory.")
        raise NotADirectoryError(f"Destination {dist_dir} is not a directory.")
    if not src.exists():
        print(f"Source file {src} does not exist.")
        raise FileNotFoundError(f"Source file {src} does not exist.")

    shutil.copyfile(src, dist, follow_symlinks=True)
    return dist


def change_kvantum(flavor):
    os.system(f'kvantummanager --set catppuccin-mocha-{flavor}')
    # execute twice to ensure the theme is installed AND applied
    os.system(f'kvantummanager --set catppuccin-mocha-{flavor}')


def change_nwglook(flavor):
    lines: list[str] = []
    with Path.home().joinpath('.local', 'share', 'nwg-look', 'gsettings').open('r') as file:
        content = file.read()
        lines = content.splitlines()
        for i, line in enumerate(lines):
            if line.startswith('gtk-theme'):
                lines[i] = f'gtk-theme=catppuccin-mocha-{flavor}-standard+default'
                break
        else:
            lines.append(f'gtk-theme=catppuccin-mocha-{flavor}-standard+default')

    with Path.home().joinpath('.local', 'share', 'nwg-look', 'gsettings').open('w') as file:
        file.write('\n'.join(lines))

    os.system('nwg-look -a')


def change_eww(flavor):
    eww_template = Path.home().joinpath('.config', 'eww', 'eww.scss.template')
    eww_dist = copy_template(eww_template, Path.home().joinpath('.config', 'eww'))
    apply_flavor(eww_dist, flavor)

    os.system('eww reload')


def change_hypr(flavor):
    hypr_template = Path.home().joinpath('.config', 'hypr', 'hyprland', 'colors.conf.template')
    hypr_dist = copy_template(hypr_template, Path.home().joinpath('.config', 'hypr', 'hyprland'))
    apply_flavor(hypr_dist, flavor)

    os.system('hyprctl reload')


def change_rofi(flavor):
    rofi_template = Path.home().joinpath('.config', 'rofi', 'config.rasi.template')
    rofi_dist = copy_template(rofi_template, Path.home().joinpath('.config', 'rofi'))
    apply_flavor(rofi_dist, flavor)


def change_waybar(flavor):
    waybar_template = Path.home().joinpath('.config', 'waybar', 'style.css.template')
    waybar_dist = copy_template(waybar_template, Path.home().joinpath('.config', 'waybar'))
    apply_flavor(waybar_dist, flavor)
    os.system('waybar-toggle.sh')


def change_ohmyposh(flavor):
    posh_template = Path.home().joinpath('.config', 'posh_theme.omp.json.template')
    posh_dist = copy_template(posh_template, Path.home().joinpath('.config'))
    apply_flavor(posh_dist, flavor)


def change_fastfetch(flavor):
    fetch_template = Path.home().joinpath('.config', 'fish', 'post.d', 'fetch.fish.template')
    fetch_dist = copy_template(fetch_template, Path.home().joinpath('.config', 'fish', 'post.d'))
    apply_flavor(fetch_dist, flavor)


def change_mako(flavor):
    mako_template = Path.home().joinpath('.config', 'mako', 'config.template')
    mako_dist = copy_template(mako_template, Path.home().joinpath('.config', 'mako'))
    apply_flavor(mako_dist, flavor)

    os.system('makoctl reload')


def change_yazi(flavor):
    yazi_template = CURRENT_DIR / '..' / '.yazi-themes' / f'catppuccin-mocha-{flavor}.toml'
    yazi_dist = Path.home().joinpath('.config', 'yazi', 'theme.toml')
    shutil.copyfile(yazi_template, yazi_dist, follow_symlinks=True)
    print(f"Copied {yazi_template} to {yazi_dist}")


def change_wlogout(flavor):
    wlogout_template = Path.home().joinpath('.config', 'wlogout', 'style.css.template')
    wlogout_dist = copy_template(wlogout_template, Path.home().joinpath('.config', 'wlogout'))
    apply_flavor(wlogout_dist, flavor)

    for icon_template in Path.home().joinpath('.config', 'wlogout', 'icons').glob('*.svg.template'):
        icon_dist = copy_template(icon_template, Path.home().joinpath('.config', 'wlogout', 'icons'))
        apply_flavor(icon_dist, flavor)


def match_color(color: str) -> str:
    """ Matches a given color to the closest color in the palette."""
    # HUE distance of the given and returned color must no<t exceed this value
    HUE_THRESHOLD = 60.0  # degrees

    if not color.startswith('#'):
        color = f'#{color}'
    color = color.lstrip('#')

    def hex2rgb(hex_color: str) -> tuple[int, int, int]:
        return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))

    def color_distance(c1: str, c2: str) -> float:
        r1, g1, b1 = hex2rgb(c1)
        r2, g2, b2 = hex2rgb(c2)
        return (r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2

    def rgb2hue(r, g, b) -> float:
        r, g, b = r / 255.0, g / 255.0, b / 255.0
        mx = max(r, g, b)
        mn = min(r, g, b)
        diff = mx - mn

        if diff == 0:
            return 0.0

        if mx == r:
            hue = (g - b) / diff + (6 if g < b else 0)
        elif mx == g:
            hue = (b - r) / diff + 2
        else:
            hue = (r - g) / diff + 4

        return hue * 60

    def color_distance_hue(c1: str, c2: str) -> float:
        r1, g1, b1 = hex2rgb(c1)
        r2, g2, b2 = hex2rgb(c2)
        return abs(rgb2hue(r1, g1, b1) - rgb2hue(r2, g2, b2))

    closest_color = min(CATPPUCIN_MOCHA_PALETTE.keys(), key=lambda k: color_distance(color, CATPPUCIN_MOCHA_PALETTE[k]))
    print(f"Matched color {color} to {closest_color}")

    # if the hue distance is too large, rematch
    if abs(rgb2hue(*hex2rgb(color)) - rgb2hue(*hex2rgb(CATPPUCIN_MOCHA_PALETTE[closest_color]))) > HUE_THRESHOLD:
        print(f"Color {color} is too far from {closest_color}, rematching'")
    else:
        return closest_color

    closest_color = min(CATPPUCIN_MOCHA_PALETTE.keys(), key=lambda k: color_distance_hue(color, CATPPUCIN_MOCHA_PALETTE[k]))
    print(f"Rematched color {color} to {closest_color}")

    return closest_color


def main():
    arguments = sys.argv[1:]
    if len(arguments) < 1:
        print("Usage: change-colortheme.py <flavor | #rrggbb> [<app1> <app2> ...]")
        sys.exit(1)

    flavor = arguments[0] if not arguments[0].startswith('#') else match_color(arguments[0])
    app = arguments[1] if len(arguments) > 1 else None

    if flavor not in CATPPUCIN_MOCHA_PALETTE:
        print(f"Unknown flavor: {flavor}. Available flavors: {', '.join(CATPPUCIN_MOCHA_PALETTE.keys())}")
        sys.exit(1)

    if app:
        function_name = f"change_{app}"
        if function_name in globals():
            func = globals()[function_name]
            try:
                print(f"Changing color theme for {app} with flavor {flavor}...")
                func(flavor)
                print("Success!")
            except Exception as e:
                print(f"Error while tweaking {app}: {e}")
        else:
            print(f"Unknown app: {app}")
    else:
        for name, func in globals().items():
            if name.startswith('change_') and callable(func):
                purename = name.removeprefix('change_')
                try:
                    print(f"Changing color theme for {purename} with flavor {flavor}...")
                    func(flavor)
                    print("Success!")
                except Exception as e:
                    print(f"Error while tweaking {purename}: {e}")

    os.system(f'notify-send "Color theme changed" "Catppuccin Mocha - {flavor}"')

    ans = input("execute \"exec fish\"? [y/N]: ").strip().lower()
    if ans in ('y', 'yes'):
        os.system('fish')


if __name__ == "__main__":
    main()
