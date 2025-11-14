# fzf
if type -q fzf
    fzf --fish | source

    # auto copy fzf's output
    if type -q wl-copy
        alias fzf="fzf --bind 'enter:execute-silent(echo {+} | wl-copy --trim-newline)+accept'"
    end

    # fzh: history
    alias fzh="history | fzf"

    # fz: fuzzy find a file and preview
    if type -q bat
        alias fz="fzf --preview 'bat --style=numbers --color=always {}'"
    else
        alias fz="fzf --preview 'cat --number {}'"
    end

    # fe: fuzzy find a file and edit using $EDITOR
    function fe
        set -l file $(fz $argv)
        if test -n "$file"
            $EDITOR "$file"
        end
    end

    # fkill: fuzzy find a process and kill with SIGKILL
    function fkill
        set -l pids (ps -ef | sed 1d | fzf -m --preview 'pstree -p $(echo {} | awk "{print \$2}")' | awk '{print $2}')

        if test -n "$pids"
            kill -9 $pids
        end
    end

    # fyq: fuzzy yay query
    if type -q yay
        alias fyq="yay -Qq | fzf --preview 'yay -Qi {}'"
    end

    # fyi: fuzzy yay install
    function fyi
        set -l pkg (yay -Sl | awk '{print $1"/"$2}' | fzf -m --preview 'yay -Si {}' $argv)
        if test -n "$pkg"
            yay -S $pkg
        end
    end

    # fyr: fuzzy yay remove
    function fyr
        set -l pkg (yay -Qq | fzf -m --preview 'yay -Qi {}' $argv)
        if test -n "$pkg"
            yay -Rn $pkg
        end
    end
end

# cd
if type -q zoxide
    zoxide init fish | source
    alias cd=z
end

# rm
if type -q trash
    alias rm="echo \"use 'trash' instead :)\"  && sh -c \"exit 42\""
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


# others
if type -q tty-clock
    alias clock="tty-clock -c -C 4"
end
