### Font packages (involved in fontconfig)

- ttf-sarasa-gothi
- ttf-symbola (AUR)
- noto-fonts
- noto-fonts-cjk
- noto-fonts-emoji
- ttf-nerd-fonts-symbols
- maplemono-nf-cn (AUR)

### Other fonts (used but not involved in fontconfig)

- Sour Gummy
- Font Awesome 6 Free
- Meslo LGM Nerd Font Mono

### Fontconfig configuration

> `~/.config/fontconfig/fonts.conf`

```xml
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
<fontconfig>
  <match target="font">
    <edit mode="assign" name="antialias"><bool>true</bool></edit>
    <edit mode="assign" name="hinting"><bool>true</bool></edit>
    <edit mode="assign" name="hintstyle"><const>hintslight</const></edit>
    <edit mode="assign" name="rgba"><const>none</const></edit>
    <edit mode="assign" name="embeddedbitmap"><bool>false</bool></edit>
    <edit mode="assign" name="lcdfilter"><const>lcddefault</const></edit>
  </match>

  <!-- For danmuku -->
  <match target="pattern">
    <test name="family">
      <string>Noto Sans CJK SC</string>
    </test>
    <edit name="family" mode="append">
      <string>Symbola</string>
    </edit>
  </match>

  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Sarasa UI SC</family>
      <family>Sarasa UI J</family>
      <family>Noto color Emoji</family>
      <family>Symbols Nerd Font</family>
    </prefer>
  </alias>

  <alias>
    <family>system-ui</family>
    <prefer>
      <family>Sarasa UI SC</family>
      <family>Sarasa UI J</family>
      <family>Noto Color Emoji</family>
      <family>Symbols Nerd Font</family>
    </prefer>
  </alias>

  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Noto Serif CJK SC</family>
      <family>Noto Serif CJK JP</family>
      <family>Noto Color Emoji</family>
      <family>Symbols Nerd Font</family>
    </prefer>
  </alias>

  <alias>
    <family>monospace</family>
    <prefer>
      <family>Maple Mono NF CN</family>
      <family>Sarasa Mono SC</family>
      <family>Sarasa Mono J</family>
      <family>Noto Color Emoji</family>
      <family>Symbols Nerd Font</family>
    </prefer>
  </alias>
</fontconfig>
```
