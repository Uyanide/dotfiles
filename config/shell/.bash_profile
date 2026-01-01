#!/bin/bash

# From archlinux's /etc/profile
append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}
prepend_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="$1${PATH:+:$PATH}"
    esac
}

# Better than nothing
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Better than nothing
if [[ -z "$LANG" ]]; then
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
fi

# Paths
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
[ -d "$HOME/go/bin" ] && prepend_path "$HOME/go/bin"
[ -d "$HOME/.local/bin" ] && prepend_path "$HOME/.local/bin"
[ -d "$HOME/.local/scripts" ] && prepend_path "$HOME/.local/scripts"
export PATH

# SSH with cross-session ssh-agent
if [ -x "$HOME/.local/scripts/ssh-init" ]; then
    eval "$($HOME/.local/scripts/ssh-init 2>/dev/null)" >/dev/null 2>&1
fi

# .profile is not included in the repo
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# Triggered when SSH into the machine
if [[ $- == *i* ]]; then
    # Set EDITOR and VISUAL, mainly for sudoedit
    for app in nvim helix vim vi nano; do
        if command -v "$app" >/dev/null 2>&1; then
            EDITOR="$app"
            VISUAL="$app"
            break
        fi
    done
    export EDITOR VISUAL

    # For gpg
    GPG_TTY=$(tty)
    export GPG_TTY

    # Shortcut alias for launching fish
    command -v f >/dev/null 2>&1 || {
        alias f="exec fish"
    }
    # Better do this manually since the automatic approach is kinda buggy.
    # Add this to .bashrc to enable it anyway:
    #
    # if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == 1 ]]; then
    #     shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    #     exec fish $LOGIN_OPTION
    # fi

    # .bashrc is not included in the repo
    [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi

unset append_path
unset prepend_path