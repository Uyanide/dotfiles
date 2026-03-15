#!/bin/bash

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
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

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

# export ENABLE_GPG_AGENT_SSH=1 in .profile to enable GPG agent for SSH
if [ -x "$HOME/.local/scripts/gpg-init" ] && \
   [ -n "$ENABLE_GPG_AGENT_SSH" ] && [ "$ENABLE_GPG_AGENT_SSH" = "1" ] && \
   type gpgconf &>/dev/null; then
	# GPG agent for SSH
	eval "$($HOME/.local/scripts/gpg-init 2>/dev/null)" &>/dev/null
elif [ -x "$HOME/.local/scripts/ssh-init" ] && type ssh-agent &>/dev/null; then
	# SSH with cross-session ssh-agent
	eval "$($HOME/.local/scripts/ssh-init 2>/dev/null)" &>/dev/null
fi

# Triggered in interactive shells (e.g. ssh)
if [[ $- == *i* ]]; then
	# Set EDITOR and VISUAL, mainly for sudoedit
	for app in nvim helix vim vi nano; do
		if type "$app" &>/dev/null; then
			EDITOR="$app"
			VISUAL="$app"
			break
		fi
	done
	export EDITOR VISUAL

	# Create shortcut alias for helix
	if type helix &>/dev/null && ! type hx &>/dev/null; then
		alias hx="helix"
	fi

	# For gpg
	if type gpgconf &>/dev/null; then
		GPG_TTY=$(tty)
		export GPG_TTY
	fi

	if [ -x "$HOME/.local/scripts/gpg-init" ] && \
   		[ -n "$ENABLE_GPG_AGENT_SSH" ] && [ "$ENABLE_GPG_AGENT_SSH" = "1" ] && \
   		type gpgconf &>/dev/null; then
		true
	elif [ -x "$HOME/.local/scripts/ssh-init" ] && type ssh-add &>/dev/null; then
		function sshs() {
			# test if keys are added to ssh-agent
			if ! ssh-add -l &>/dev/null; then
				if [ -n "$ssh_keys" ]; then
					ssh-add "${ssh_keys[@]}"
				else
					ssh-add
				fi
			fi
			ssh "$@"
		}
	fi

	# Shortcut alias for launching fish
	if type fish &>/dev/null && ! type f &>/dev/null; then
		alias f="exec fish"
	fi
	# Better do this manually since the automatic approach is kinda buggy.
	# Add this to .bashrc to enable it anyway:
	#
	# if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == 1 ]]; then
	#     shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
	#     exec fish $LOGIN_OPTION
	# fi

	# .bashrc is not included in the repo
	[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi

unset append_path
unset prepend_path
