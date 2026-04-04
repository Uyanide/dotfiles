# ssh with encrypted private keys
# $ssh_keys should be set in advance or left empty to use the default keys

if set -q UY_ENABLE_GPG_AGENT_SSH; and test $UY_ENABLE_GPG_AGENT_SSH != "0";\
   and type -q gpg-init; and type -q gpgconf

   true # do nothing

else if type -q ssh-init; and type -q ssh-add
    # avoid entering passphrase every time
    function sshs
        # test if keys are added to ssh-agent
        if not ssh-add -l > /dev/null 2>&1
            ssh-add $ssh_keys
        end
        ssh $argv
    end
end
