#!/hint/bash

# From archlinux's /etc/profile
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

# .profile is not included in the repo
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# Better than nothing
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# Better than nothing
if [[ -z "$LANG" ]]; then
	LANG="en_US.UTF-8"
	export LANG
fi

# Paths
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
prepend_path "$HOME/go/bin"
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.local/scripts"
prepend_path "$HOME/.local/share/fnm"
export PATH

# fnm
if type fnm &>/dev/null; then
	eval "$(fnm env --shell bash)"
fi

# export UY_ENABLE_GPG_AGENT_SSH=1 in .profile to enable GPG agent for SSH
if type gpgconf &>/dev/null && type gpg-connect-agent &>/dev/null &&
	[ -x "$HOME/.local/scripts/gpg-init" ] &&
   	[ "${UY_ENABLE_GPG_AGENT_SSH:-0}" = "1" ]; then
	# GPG agent for SSH
	eval "$($HOME/.local/scripts/gpg-init 2>/dev/null)" &>/dev/null
fi

if type ssh-add &>/dev/null && type ssh-agent &>/dev/null &&
	{ [ -z "$SSH_AUTH_SOCK" ] ||
	  [ "$(ssh-add -l &>/dev/null; echo $?)" -eq 2 ]; } &&
	[ -x "$HOME/.local/scripts/ssh-init" ]; then
	unset SSH_AUTH_SOCK
	# SSH with cross-session ssh-agent
	eval "$($HOME/.local/scripts/ssh-init 2>/dev/null)" &>/dev/null
	export UY_USING_SSH_AGENT=1
fi

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

unset append_path
unset prepend_path
