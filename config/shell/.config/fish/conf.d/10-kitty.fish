# Workaround: https://github.com/kovidgoyal/kitty/issues/9416
if test "$TERM" = "xterm-kitty"; and type -q kitty; and kitty --version | grep -q "0.45.0"
    set -xg TERM "xterm-256color"
    set -xg TERMINFO "/usr/share/terminfo"
end
