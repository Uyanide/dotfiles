# MANPAGER

if (( $+commands[bat] )); then
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
	export MANROFFOPT=-c
fi

# Editor

for _uy_app in nvim helix vim vi nano; do
	if (( $+commands[$_uy_app] )); then
		export EDITOR=$_uy_app
		export VISUAL=$_uy_app
		break
	fi
done
unset _uy_app

if (( $+commands[helix] )) && ! (( $+commands[hx] )); then
	alias hx=helix
fi

# GPG

if (( $+commands[gpg] )); then
	export GPG_TTY=$(tty)
fi

# Catppuccin Mocha — autosuggestions color

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
