if type -q fzf
    fzf --fish | source

    if type -q wl-copy
        function fzc
            fzf $argv | string collect | wl-copy
        end
    end
end

if type -q zoxide
    zoxide init fish | source
    alias cd=z
end

if type -q trash
    alias rm="echo \"use 'trash' instead :)\"  && sh -c \"exit 42\""
end