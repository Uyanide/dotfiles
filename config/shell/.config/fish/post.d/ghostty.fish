if string match -q '*ghostty*' $TERM && test $XDG_CURRENT_DESKTOP = niri
    if test "$ghostty_niri_initialized" != "1"
        set -xg ghostty_niri_initialized 1
        niri msg action set-column-width 50%
    end
end