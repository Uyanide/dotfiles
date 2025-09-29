# ssh with encrypted private keys
# $ssh_keys should be set in advance or left empty to use default keys
if type -q ssh
    # start ssh agent if not already running
    if not set -q SSH_AUTH_SOCK
        if test -f "$HOME/.ssh-agent" -a -r "$HOME/.ssh-agent"
            bass source "$HOME/.ssh-agent" > /dev/null 2>&1
            # check if the socket is actually working
            if not ssh-add -l > /dev/null 2>&1
                command rm -f "$HOME/.ssh-agent"
                set -e SSH_AUTH_SOCK
            end
        end

        if not set -q SSH_AUTH_SOCK 2>&1
            command rm -f "$HOME/.ssh-agent"
            bass eval (ssh-agent -s | tee "$HOME/.ssh-agent") > /dev/null 2>&1
        end
    end

    # only need to input passphrase once per session
    function sshs
        # test if keys are added to ssh-agent
        if not ssh-add -l > /dev/null 2>&1
            ssh-add $ssh_keys
        end
        ssh $argv
    end
end