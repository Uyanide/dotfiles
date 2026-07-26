# Plugins that wrap ZLE widgets. Deliberately the last conf.d file:
#   - fzf-tab must load after compinit (03-compinit.zsh)
#   - fzf-tab must load before the plugins that wrap widgets
#   - zsh-syntax-highlighting must load after everything that defines a widget,
#     i.e. after 50-prompt.zsh (zle hooks) and 60-alias.zsh (`fzf --zsh`)
# Load order inside .zsh_plugins.txt matters and encodes the same rules.

if (( $+functions[antidote] )); then
    _uy_zsh_plugins="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zsh_plugins.txt"
    if [[ -f "$_uy_zsh_plugins" ]]; then
        antidote load "$_uy_zsh_plugins"
    fi
fi

unset _uy_zsh_plugins
