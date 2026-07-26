# fzf
if type -q fzf
    fzf --fish | source

    # use fd if available
    if type -q fd
        set -g FD_CMD "fd"
    else if type -q fdfind
        set -g FD_CMD "fdfind"
    end
    if test -n "$FD_CMD"
        set -x FZF_DEFAULT_COMMAND "$FD_CMD --type f --hidden --exclude .git"
        set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        set -x FZF_ALT_C_COMMAND "$FD_CMD --type d --hidden --exclude .git"
    end

    # C-y to copy fzf's output
    if type -q wl-copy
        set -x FZF_DEFAULT_OPTS "--bind \"ctrl-y:execute-silent(echo -n {+} | wl-copy)+abort\""
    end
end

# cd
if type -q zoxide
    zoxide init fish | source
    alias cd=z
end

# rm
# if type -q trash
#     alias rm="echo \"use 'trash' instead :)\"  && sh -c \"exit 42\""
# end

# ls
if type -q eza
    alias ls="eza --color=auto --hyperlink=auto"
    alias ll="eza -lh --group-directories-first --icons=auto --hyperlink=auto"
    alias la="eza -lh --group-directories-first --icons=auto --hyperlink=auto --all"
    alias lt="eza --tree --level=2 --long --icons --git --hyperlink=auto"
else
    alias ls="ls --color=auto --hyperlink=auto"
    alias ll="ls -lh --group-directories-first --color=auto --hyperlink=auto"
    alias la="ls -lah --group-directories-first --color=auto --hyperlink=auto"
end

# directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# colorize
alias grep="grep --color=auto"
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias diff="diff --color=auto"

# wget
if type -q wget
    alias wget="wget -c"
end

# Sort pacman packages by size
if type -q expac
    alias big="expac -H M '%m\t%n' | sort -h | nl"
end

# clock
if type -q tty-clock
    alias clock="tty-clock -c -C 4"
end

# journalctl
alias jctl="journalctl -p 3 -xb"

# nohup
function nh
    nohup $argv >/dev/null 2>&1 & disown
end

# ffmpeg
alias ffmpeg="ffmpeg -hide_banner -nostdin"
alias ffprobe="ffprobe -hide_banner"
