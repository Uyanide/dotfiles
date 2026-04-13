#!/hint/bash

[[ $- == *i* ]] || return

if type fish &>/dev/null; then
	alias f="exec fish"

	if [[ ${UY_ENABLE_FISH_AUTO_LOGIN:-0} == 1 ]] &&
		[[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == 1 ]]; then
		shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
		exec fish $LOGIN_OPTION
	fi
fi

HISTCONTROL=ignoreboth
HISTSIZE=16384
HISTFILESIZE=32768
shopt -s histappend checkwinsize

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
alias ls='ls --color=auto'
alias grep='grep --color=auto'

alias ll='ls -l' la='ls -A' l='ls -CF'

if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

for app in nvim helix vim vi nano; do
	if type "$app" &>/dev/null; then
		EDITOR="$app"
		VISUAL="$app"
		break
	fi
done
export EDITOR VISUAL

if type helix &>/dev/null && ! type hx &>/dev/null; then
	alias hx="helix"
fi

if type gpg &>/dev/null; then
	GPG_TTY=$(tty)
	export GPG_TTY
fi

if type fnm &>/dev/null; then
	eval "$(fnm env --shell bash --use-on-cd)"
fi

if [[ ${UY_USING_SSH_AGENT:-0} == 1 ]]; then
	function sshs() {
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

if type starship &>/dev/null; then
	eval "$(starship init bash)"
fi
