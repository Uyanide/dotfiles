#!/hint/zsh

# Login shell only — runs once per session

# GPG agent for SSH

if (( $+commands[gpgconf] )) && (( $+commands[gpg-connect-agent] )) &&
	[[ -x "$HOME/.local/scripts/gpg-init" ]] &&
	[[ "${UY_ENABLE_GPG_AGENT_SSH:-0}" = "1" ]]; then
	eval "$($HOME/.local/scripts/gpg-init 2>/dev/null)" &>/dev/null
fi

# SSH agent

if (( $+commands[ssh-add] )) && (( $+commands[ssh-agent] )); then
	# ssh-add -l: 0 = agent with keys, 1 = agent without keys, 2 = no agent
	if [[ -n "$SSH_AUTH_SOCK" ]] &&
		{ ssh-add -l &>/dev/null; [[ $? -ne 2 ]]; }; then
		export UY_USING_SSH_AGENT=1
	elif [[ -x "$HOME/.local/scripts/ssh-init" ]]; then
		unset SSH_AUTH_SOCK
		eval "$($HOME/.local/scripts/ssh-init 2>/dev/null)" &>/dev/null
		[[ -n "$SSH_AUTH_SOCK" ]] && export UY_USING_SSH_AGENT=1
	fi
fi
