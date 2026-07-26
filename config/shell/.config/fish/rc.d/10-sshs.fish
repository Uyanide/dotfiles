# ssh with encrypted private keys
# $uy_ssh_keys should be set in a device-specific file or left empty for defaults

if test "$UY_ENABLE_GPG_AGENT_SSH" = 1;\
   and test -x "$HOME/.local/scripts/gpg-init"; and type -q gpgconf

   true # GPG agent handles SSH — nothing to do

else if test "$UY_USING_SSH_AGENT" = 1
    # avoid entering passphrase every time
    function sshs
        # test if keys are added to ssh-agent
        if not ssh-add -l > /dev/null 2>&1
            ssh-add $uy_ssh_keys
        end
        ssh $argv
    end
end
