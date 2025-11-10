# ssh with encrypted private keys
# $ssh_keys should be set in advance or left empty to use the default keys
if type -q ssh
    bass $(ssh-init) > /dev/null 2>&1

    # avoiding entering passphrase every time
    function sshs
        # test if keys are added to ssh-agent
        if not ssh-add -l > /dev/null 2>&1
            ssh-add $ssh_keys
        end
        ssh $argv
    end
end