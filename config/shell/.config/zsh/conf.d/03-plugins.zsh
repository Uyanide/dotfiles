_uy_antidote_dir="${XDG_DATA_HOME:-$HOME/.local/share}/antidote"

# Find antidote: system package → user-local clone → auto-bootstrap
if [[ -f /usr/share/zsh-antidote/antidote.zsh ]]; then
    source /usr/share/zsh-antidote/antidote.zsh
elif [[ -f "$_uy_antidote_dir/antidote.zsh" ]]; then
    source "$_uy_antidote_dir/antidote.zsh"
elif (( $+commands[git] )); then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$_uy_antidote_dir"
    source "$_uy_antidote_dir/antidote.zsh"
fi

if (( $+functions[antidote] )); then
    _uy_zsh_plugins="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zsh_plugins.txt"
    if [[ -f "$_uy_zsh_plugins" ]]; then
        antidote load "$_uy_zsh_plugins"
    fi
fi

unset _uy_antidote_dir _uy_zsh_plugins
