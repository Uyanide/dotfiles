#!/hint/zsh

append_path() {
	[[ -z "$1" ]] && return
	[[ -d "$1" ]] || return
	case ":$PATH:" in
	*:"$1":*) ;;
	*)
		PATH="${PATH:+$PATH:}$1"
		;;
	esac
}
prepend_path() {
	[[ -z "$1" ]] && return
	[[ -d "$1" ]] || return
	case ":$PATH:" in
	*:"$1":*) ;;
	*)
		PATH="$1${PATH:+:$PATH}"
		;;
	esac
}

# XDG, better than not set

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# Locale, better than not set

if [[ -z "$LANG" ]]; then
	export LANG="en_US.UTF-8"
fi

# Somewhat expensive

if [[ -z "$UY_ENV_DONE" ]]; then
  [[ -f "$HOME/.profile" ]] && . "$HOME/.profile"
  (( $+commands[opam] )) && eval "$(opam env)"
  export UY_ENV_DONE=1
fi

# Paths

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
(( $+commands[opam] )) && eval "$(opam env)"
prepend_path "$HOME/.local/share/fnm/aliases/default/bin" # 'fnm env' is eval'ed in .zshrc
prepend_path "$HOME/.cargo/bin"
prepend_path "$HOME/go/bin"
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.local/scripts"
prepend_path "$HOME/.local/share/fnm"
export PATH

unfunction append_path
unfunction prepend_path
