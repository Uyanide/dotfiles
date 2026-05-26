### Font packages (involved in fontconfig)

- `aur/ttf-symbola`
- `extra/noto-fonts`
- `extra/noto-fonts-cjk`
- `extra/noto-fonts-emoji`
- `extra/ttf-nerd-fonts-symbols`
- `aur/maplemono-nf-cn`

### Other fonts (used but not involved in fontconfig)

- Sour Gummy (from [Google Fonts](https://fonts.google.com/specimen/Sour+Gummy))
- Font Awesome 6 Free (extracted from an AUR package that no longer exists)
- `extra/ttf-meslo-nerd`
- `archlinuxcn/ttf-lxgw-wenkai`

### Font configuration

```xml
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
<fontconfig>
 <match target="font">
  <edit mode="assign" name="antialias">
   <bool>true</bool>
  </edit>
  <edit mode="assign" name="hinting">
   <bool>true</bool>
  </edit>
  <edit mode="assign" name="hintstyle">
   <const>hintslight</const>
  </edit>
  <edit mode="assign" name="rgba">
   <const>none</const>
  </edit>
  <!-- <edit mode="assign" name="embeddedbitmap"><bool>false</bool></edit> -->
 </match>
 <alias>
  <family>sans-serif</family>
  <prefer>
   <!-- <family>LXGW WenKai</family> -->
   <family>Noto Sans</family>
   <family>Noto Sans CJK SC</family>
   <family>Noto Sans CJK JP</family>
   <family>Noto Sans CJK KR</family>
   <family>Noto Color Emoji</family>
   <family>Symbols Nerd Font</family>
  </prefer>
 </alias>
 <alias>
  <family>danmaku</family>
  <prefer>
   <family>Noto Sans</family>
   <family>Noto Sans CJK SC</family>
   <family>Noto Sans CJK JP</family>
   <family>Noto Sans CJK KR</family>
   <family>Symbola</family>
  </prefer>
 </alias>
 <alias>
  <family>system-ui</family>
  <prefer>
   <family>sans-serif</family>
  </prefer>
 </alias>
 <alias>
  <family>serif</family>
  <prefer>
   <family>Noto Serif</family>
   <family>Noto Serif CJK SC</family>
   <family>Noto Serif CJK JP</family>
   <family>Noto Serif CJK KR</family>
   <family>Noto Color Emoji</family>
   <family>Symbols Nerd Font</family>
  </prefer>
 </alias>
 <alias>
  <family>monospace</family>
  <prefer>
   <!-- <family>ComicShanns Nerd Font</family> -->
   <family>Maple Mono NF CN</family>
   <family>Noto Sans Mono</family>
   <family>Noto Sans Mono CJK SC</family>
   <family>Noto Sans Mono CJK JP</family>
   <family>Noto Sans Mono CJK KR</family>
   <family>Noto Color Emoji</family>
   <family>Symbols Nerd Font</family>
  </prefer>
 </alias>
 <alias>
  <family>標楷體</family>
  <prefer>
   <family>LXGW WenKai</family>
  </prefer>
 </alias>
 <dir>~/.local/share/fonts</dir>
</fontconfig>

```

### Notes

- `~/.fonts/` is deprecated, use `~/.local/share/fonts/` instead.

- `~/.config/fontconfig/fonts.conf` will be loaded by `/etc/fonts/conf.d/50-user.conf` and therefore takes precedence over the rules defined in files starting with a higher number.
