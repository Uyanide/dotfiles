# fzf
if type -q fzf
    fzf --fish | source

    # use fd if available
    if type -q fd
        set -x FD_CMD "fd"
    else if type -q fdfind
        set -x FD_CMD "fdfind"
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

    # fz: fuzzy find a file and preview
    if type -q bat
		alias fz="fzf --preview 'bat --style=numbers --color=always {}'"
	else
		alias fz="fzf --preview 'cat -n {}'"
    end

    # fe: fuzzy find a file and edit using $EDITOR
    function fe
        set -l file $(fz --header "[edit with $EDITOR]")
        if test -n "$file"
            $EDITOR "$file"
        end
    end

    # fkp: fuzzy find a process and kill with SIGKILL
    function fkp
        set -l pids (ps -ef | sed 1d | fzf -m --preview 'pstree -p $(echo {} | awk "{print \$2}")' --header '[kill process]' | awk '{print $2}')

        if test -n "$pids"
            kill -9 $pids
        end
    end

    # fks: fuzzy find a TCP process and kill with SIGKILL
    if type -q ss
        function fks
            set -l entries (sudo ss -lptn)
            set -l pids (echo "$entries" | fzf -m --header-lines 1 --header '[kill process]' | grep -oP 'pid=\K\d+')
            if test -n "$pids"
                sudo kill -9 $pids
            end
        end
    end

    if type -q yay
        # fyq: fuzzy yay query
        alias fyq="yay -Qq | fzf --preview 'yay -Qi {}'"

        # fyi: fuzzy yay install
        function fyi
            set -l pkg (yay -Sl | awk '{print $1"/"$2}' | fzf -m --preview 'yay -Si {}' --header "[install package]" $argv)
            if test -n "$pkg"
                yay -S $pkg
            end
        end

        # fyr: fuzzy yay remove
        function fyr
            set -l pkg (yay -Qq | fzf -m --preview 'yay -Qi {}' --header "[remove package]" $argv)
            if test -n "$pkg"
                yay -Rn $pkg
            end
        end
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

# copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end


# wget
if type -q wget
    alias wget="wget -c "
end

# colorize
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

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

# git
if type -q git
    function gcp
        git add -A || return 1
        if test (count $argv) -eq 0
            git commit -m "👐 foo: too lazy to come up with a helpful commit message :)" || return 1
        else
            git commit -m "$argv" || return 1
        end
        git push
    end

    if type -q wl-paste
        # alias gc="git clone \$(wl-paste)"
        function gc
            set -l repo (wl-paste)
            if not string match -r '^(http|https|git|ssh)://|^git@' "$repo" >/dev/null 2>&1
                echo "Error: Clipboard does not contain a valid git repository URL." >&2
                echo "Error: Clipboard content: $repo" >&2
                read -P "Enter a valid git repository URL: " repo
                if not string match -r '^(http|https|git|ssh)://|^git@' "$repo"
                    echo "Error: Invalid git repository URL." >&2
                    return 1
                end
            end
            git clone $repo
        end

        function pingo
            cd "$HOME/Repositories/PGdP" || return 1
            set -l repo (wl-paste)
            if not string match -r '^(http|https|git|ssh)://|^git@' "$repo" >/dev/null 2>&1
                echo "Error: Clipboard does not contain a valid git repository URL." >&2
                echo "Error: Clipboard content: $repo" >&2
                read -P "Enter a valid git repository URL: " repo
                if not string match -r '^(http|https|git|ssh)://|^git@' "$repo"
                    echo "Error: Invalid git repository URL." >&2
                    return 1
                end
            end
            set -l dir_name (basename "$repo" .git)
            if ! test -d "$dir_name"
                git clone $repo || return 1
            end
            set -l app $argv[1]
            if test -n "$app"; and type -q "$app"
                echo Opening project with "$app"
                nohup $app $dir_name >/dev/null 2>&1 & disown
            else
                echo Opening method missing or invalid
                cd $dir_name
            end
        end
    end
end
