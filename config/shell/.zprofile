#!/hint/zsh

# Login shell only — runs once per session (like .bash_profile)

# Path helpers (needed before sourcing .profile)

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

# .profile is not included in the repo (private / per-device)
[[ -f "$HOME/.profile" ]] && . "$HOME/.profile"

# Paths

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
prepend_path "$HOME/go/bin"
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.local/scripts"
prepend_path "$HOME/.local/share/fnm"
export PATH

# GPG agent for SSH

if (( $+commands[gpgconf] )) && (( $+commands[gpg-connect-agent] )) &&
	[[ -x "$HOME/.local/scripts/gpg-init" ]] &&
	[[ "${UY_ENABLE_GPG_AGENT_SSH:-0}" = "1" ]]; then
	eval "$($HOME/.local/scripts/gpg-init 2>/dev/null)" &>/dev/null
fi

# SSH agent

if (( $+commands[ssh-add] )) && (( $+commands[ssh-agent] )) &&
	{ [[ -z "$SSH_AUTH_SOCK" ]] ||
	  { ssh-add -l &>/dev/null; [[ $? -eq 2 ]]; } } &&
	[[ -x "$HOME/.local/scripts/ssh-init" ]]; then
	unset SSH_AUTH_SOCK
	eval "$($HOME/.local/scripts/ssh-init 2>/dev/null)" &>/dev/null
	export UY_USING_SSH_AGENT=1
fi

unfunction append_path
unfunction prepend_path
