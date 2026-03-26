# Fallback prompt (if oh-my-posh is not available)
PROMPT='%F{blue}%n@%m%f %F{cyan}%~%f > '

# oh-my-posh
if [[ -f "$HOME/.config/posh_theme.omp.json" ]] && (( $+commands[oh-my-posh] )); then
	eval "$(oh-my-posh init zsh --config "$HOME/.config/posh_theme.omp.json")"
fi
