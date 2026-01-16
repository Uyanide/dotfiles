# ssh with encrypted private keys
# $ssh_key_hashes should be set in advance or left empty to use the default keys

if set -q ENABLE_GPG_AGENT_SSH; and test $ENABLE_GPG_AGENT_SSH != "0";\
   and type -q gpg-init; and type -q gpgconf
    # GPG agent for SSH
    bass $(gpg-init) > /dev/null 2>&1

else if type -q ssh-init; and type -q ssh-add
    # SSH with cross-session ssh-agent
    bass $(ssh-init) > /dev/null 2>&1

    # avoid entering passphrase every time
    function sshs
        # test if keys are added to ssh-agent
        if not ssh-add -l > /dev/null 2>&1
            ssh-add $ssh_keys
        end
        ssh $argv
    end
end
