# Fallback prompt (if oh-my-posh is not available)
PROMPT='%F{blue}%n@%m%f %F{cyan}%~%f > '

# starship
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"

    # accent of the [palettes.<name>] named by the top-level `palette` key.
    function uy_starship_accent() {
        setopt local_options extended_glob
        local line palette in_palette=0
        local -a lines
        [[ -r $1 ]] || return 1
        lines=( ${(f)"$(<$1)"} )

        for line in $lines; do
            if [[ $line == palette[[:blank:]]#=[[:blank:]]#\'*\' ]]; then
                palette=${${line#*\'}%\'}
                break
            fi
        done
        [[ -n $palette ]] || return 1

        for line in $lines; do
            if (( in_palette )); then
                [[ $line == \[* ]] && return 1
                if [[ $line == accent[[:blank:]]#=[[:blank:]]#\"*\" ]]; then
                    REPLY=${${line#*\"}%\"}
                    return 0
                fi
            elif [[ $line == "[palettes.$palette]" ]]; then
                in_palette=1
            fi
        done
        return 1
    }

    function uy_transient_prompt() {
        local REPLY
        uy_starship_accent "${STARSHIP_CONFIG:-$HOME/.config/starship.toml}" &&
            uy_accent=$REPLY

        PROMPT="%F{${uy_accent:-blue}}$%f " zle .reset-prompt
    }

    autoload -Uz add-zle-hook-widget
    add-zle-hook-widget zle-line-finish uy_transient_prompt

# oh-my-posh
elif [[ -f "$HOME/.config/posh_theme.omp.json" ]] && (( $+commands[oh-my-posh] )); then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/posh_theme.omp.json")"
fi
