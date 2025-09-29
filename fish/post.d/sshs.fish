# ssh with encrypted private keys
# $ssh_keys should be set in advance or left empty to use default keys
if type -q ssh
    bass $(ssh-init) > /dev/null 2>&1

    # only need to input passphrase once per session
    function sshs
        # test if keys are added to ssh-agent
        if not ssh-add -l > /dev/null 2>&1
            ssh-add $ssh_keys
        end
        ssh $argv
    end
end