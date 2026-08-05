# fzf

if (( $+commands[fzf] )); then
    source <(fzf --zsh)

    # use fd if available (search cwd only, skip vcs/cache junk)
    if (( $+commands[fd] )); then
        FD_CMD="fd"
    elif (( $+commands[fdfind] )); then
        FD_CMD="fdfind"
    fi
    if [[ -n "$FD_CMD" ]]; then
        export FZF_DEFAULT_COMMAND="$FD_CMD --type f --hidden --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND="$FD_CMD --type d --hidden --exclude .git"
    fi

    # C-y to copy fzf's output
    if (( $+commands[wl-copy] )); then
        export FZF_DEFAULT_OPTS="--bind \"ctrl-y:execute-silent(echo -n {+} | wl-copy)+abort\""
    fi

    # fz: fuzzy find a file and preview
    if (( $+commands[bat] )); then
        alias fz="fzf --preview 'bat --style=numbers --color=always {}'"
    else
        alias fz="fzf --preview 'cat -n {}'"
    fi

    # fe: fuzzy find a file and edit using $EDITOR
    fe() {
        local file
        file=$(fz --header "[edit with $EDITOR]")
        [[ -n "$file" ]] && $EDITOR "$file"
    }

    # fkp: fuzzy find a process and kill
    fkp() {
        local pids
        pids=$(ps -ef | fzf -m --header-lines 1 --preview 'pstree -p $(echo {} | awk "{print \$2}")' --header "[kill process]" | awk '{print $2}')
        echo "$pids" | xargs -r kill -${1:-9}
    }

    # fks: fuzzy find a TCP process and kill
    if (( $+commands[ss] )); then
        fks() {
            local pids
            # Call sudo separately since one cannot enter password in fzf's window
            pids=$(sudo ss -lptn)
            pids=$(echo "$pids" | fzf -m --header-lines 1 --header "[kill process]" | grep -oP 'pid=\K\d+')
            echo "$pids" | xargs -r sudo kill -${1:-9}
        }
    fi

    if (( $+commands[yay] )); then
        # fyq: fuzzy yay local query
        alias fyq="yay -Qq | fzf --preview 'yay -Qi {}' --preview-window='right,70%,wrap'"

        # fyi: fuzzy yay install
        fyi() {
            local pkg
            pkg=$(yay -Sl | awk '{print $1"/"$2}' | fzf -m --preview 'yay -Si {}' --preview-window='right,70%,wrap' --header "[install package]" "$@")
            # yay supports "repo/package" format
            [[ -n "$pkg" ]] && yay -S ${=pkg}
        }

        # fyr: fuzzy yay remove
        fyr() {
            local pkg
            pkg=$(yay -Qq | fzf -m --preview 'yay -Qi {}' --preview-window='right,70%,wrap' --header "[remove package]" "$@")
            [[ -n "$pkg" ]] && yay -Rn ${=pkg}
        }
    fi
fi

# cd (zoxide)

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
    alias cd=z
fi

# ls

if (( $+commands[eza] )); then
    alias ls="eza --color=auto --hyperlink=auto"
    alias ll="eza -lh --group-directories-first --icons=auto --hyperlink=auto"
    alias la="eza -lh --group-directories-first --icons=auto --hyperlink=auto --all"
    alias lt="eza --tree --level=2 --long --icons --git --hyperlink=auto"
else
    alias ls="ls --color=auto --hyperlink=auto"
    alias ll="ls -lh --group-directories-first --color=auto --hyperlink=auto"
    alias la="ls -lah --group-directories-first --color=auto --hyperlink=auto"
fi

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

# copy

copy() {
    if [[ $# -eq 2 && -d "$1" ]]; then
        command cp -r "${1%/}" "$2"
    else
        command cp "$@"
    fi
}

# wget

if (( $+commands[wget] )); then
    alias wget="wget -c"
fi

# pacman

if (( $+commands[expac] )); then
    alias big="expac -H M '%m\t%n' | sort -h | nl"
fi

# clock

if (( $+commands[tty-clock] )); then
    alias clock="tty-clock -c -C 4"
fi

# journalctl

alias jctl="journalctl -p 3 -xb"

# nohup

nh() {
    nohup "$@" >/dev/null 2>&1 &
    disown
}

# ffmpeg

alias ffmpeg="ffmpeg -hide_banner -nostdin"
alias ffprobe="ffprobe -hide_banner"

# git

if (( $+commands[git] )); then
    gcp() {
        git add -A || return 1
        if [[ $# -eq 0 ]]; then
            git commit -m "👐 foo:)" || return 1
        else
            git commit -m "$*" || return 1
        fi
        git push
    }

    if (( $+commands[wl-paste] )); then
        # Get a git repo URL from clipboard, prompting if invalid
        uy_git_repo_from_clipboard() {
            local repo
            repo=$(wl-paste)
            if [[ ! "$repo" =~ '^(http|https|git|ssh)://|^git@' ]]; then
                echo "Error: Clipboard does not contain a valid git repository URL." >&2
                echo "Error: Clipboard content: $repo" >&2
                read "repo?Enter a valid git repository URL: "
                if [[ ! "$repo" =~ '^(http|https|git|ssh)://|^git@' ]]; then
                    echo "Error: Invalid git repository URL." >&2
                    return 1
                fi
            fi
            print -r -- "$repo"
        }

        gcl() {
            local repo
            repo=$(uy_git_repo_from_clipboard) || return 1
            git clone "$repo"
        }

        pingo() {
            builtin cd "$HOME/Repositories/Uni" || return 1
            local repo
            repo=$(uy_git_repo_from_clipboard) || return 1
            local dir_name="${repo:t:r}"
            local course="${${dir_name%%[^[:lower:]]*}:u}"
            mkdir -p "$course"
            builtin cd "$course" || return 1
            if [[ ! -d "$dir_name" ]]; then
                git clone "$repo" || return 1
            fi
            builtin cd "$dir_name"
            local app="$1"
            if [[ -n "$app" ]] && (( $+commands[$app] )); then
                echo "Opening project with $app"
                # nohup "$app" . >/dev/null 2>&1 &
                # disown
                if [[ ${XDG_CURRENT_DESKTOP:-} = "niri" ]]; then
                  niri msg action spawn -- "$app" "$HOME/Repositories/Uni/$course/$dir_name"
                else
                  nohup "$app" . >/dev/null 2>&1 &
                  disown
                fi
            fi
        }
    fi
fi

# jj
if (( $+commands[jj] )); then
    jjc() {
        jj describe -m "$*"
        jj new
    }

    jjp() {
        default_branch() {
            local ref
            ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
            if [[ -n "$ref" ]]; then
                print -r -- "${ref:t}"
                return
            fi
            ref=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
            print -r -- "${ref:-master}"
        }
        local branch pos
        branch=${1:-$(default_branch)}
        pos=${2:-@-}
        jj bookmark move "$branch" --to "$pos"
        jj git push
        unfunction default_branch
    }

    alias jja="jj log -r 'all()' -T builtin_log_detailed"
fi

# Global aliases (can be used as part of a command)

# wl-paste
if (( $+commands[wl-paste] )); then
    alias -g CP="| wl-copy"
fi

# Redirects
alias -g NE="2>/dev/null"
alias -g NO=">/dev/null"
alias -g EO="2>&1"
alias -g NUL="&>/dev/null"
