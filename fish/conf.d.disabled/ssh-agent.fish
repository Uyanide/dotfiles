if test -z "$SSH_AUTH_SOCK"
    eval (command ssh-agent -c) >/dev/null 2>&1
    for key in $HOME/.ssh/keys/*
        if test -f $key
            command ssh-add $key >/dev/null 2>&1
        end
    end
end