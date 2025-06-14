set -l theme 'Catpuccin Mocha'

if not set -q fish_current_theme; or not string match -q "$theme" "$fish_current_theme"
    set -U fish_current_theme "$theme"
    fish_config theme save "$theme"
end