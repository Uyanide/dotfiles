set -l target_ver 3.4.0

if test (string join \n $FISH_VERSION $target_ver | sort -V | head -n 1) = $target_ver
    set -l theme 'Catppuccin Mocha'

    if not set -q fish_current_theme; or not string match -q "$theme" "$fish_current_theme"
        set -U fish_current_theme "$theme"
        fish_config theme save "$theme"
    end
end
