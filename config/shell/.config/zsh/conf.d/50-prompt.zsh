# Fallback prompt (if oh-my-posh is not available)
PROMPT='%F{blue}%n@%m%f %F{cyan}%~%f > '

# starship
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"

    autoload -Uz add-zle-hook-widget
    add-zle-hook-widget zle-line-finish transient-prompt

    function transient-prompt() {
        local file palette color
        file=${STARSHIP_CONFIG:-"$HOME/.config/starship.toml"}
        palette=$(sed -n "s/^palette\s*=\s*'\(.*\)'/\1/p" "$file")
        color=$(sed -n "/^\[palettes\.${palette}\]/,/^\[/{s/^accent\s*=\s*\"\(.*\)\"/\1/p}" "$file")

        PROMPT="%F{$color}#%f " zle .reset-prompt
    }


# oh-my-posh
elif [[ -f "$HOME/.config/posh_theme.omp.json" ]] && (( $+commands[oh-my-posh] )); then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/posh_theme.omp.json")"
fi

