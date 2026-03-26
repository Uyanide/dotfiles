# ssh with encrypted private keys
# $uy_ssh_keys should be set in a device-specific file or left empty for defaults

if [[ "${UY_ENABLE_GPG_AGENT_SSH:-0}" = "1" ]] &&
   (( $+commands[gpg-init] )) && (( $+commands[gpgconf] )); then
	: # GPG agent handles SSH — nothing to do

elif [[ "${UY_USING_SSH_AGENT:-0}" = "1" ]]; then
	sshs() {
		if ! ssh-add -l &>/dev/null; then
			if [[ -n "${uy_ssh_keys[*]}" ]]; then
				ssh-add "${uy_ssh_keys[@]}"
			else
				ssh-add
			fi
		fi
		ssh "$@"
	}
fi
