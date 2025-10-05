# fzf
if type -q fzf
    fzf --fish | source

    if type -q wl-copy
        function fzc
            fzf $argv | string collect | wl-copy
        end
    end

    if type -q bat
        alias fz="fzf --preview 'bat --style=numbers --color=always {}'"
    end
end


# cd
if type -q zoxide
    zoxide init fish | source
    alias cd=z
end

# rm
if type -q trash
    alias rm="echo \"use 'trash' instead :)\"  && sh -c \"exit 42\" && echo why do you see this line :O"
end

# ls
if type -q eza
    alias ll="eza -lh --group-directories-first --icons=auto"
    alias la="eza -lh --group-directories-first --icons=auto --all"
    alias lt="eza --tree --level=2 --long --icons --git"
else
    alias ll="ls -lh --group-directories-first --color=auto"
    alias la="ls -lah --group-directories-first --color=auto"
end

# directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# grep
alias grep="grep --color=auto"

# nvim
if type -q nvim
    set -x -g EDITOR nvim
    set -x -g VISUAL nvim
end

# others
if type -q tty-clock
    alias clock="tty-clock -c -C 3"
end
