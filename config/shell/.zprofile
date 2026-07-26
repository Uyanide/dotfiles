#!/hint/zsh

# Login shell only — runs once per session

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
