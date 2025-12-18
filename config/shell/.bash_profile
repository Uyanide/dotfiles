[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.local/scripts" ] && export PATH="$HOME/.local/scripts:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"

[ -x "$HOME/.local/scripts/ssh-init" ] && eval "$(ssh-init)" >/dev/null 2>&1

command -v nvim >/dev/null 2>&1 && {
    export EDITOR=nvim
    export VISUAL=nvim
}

command -v f >/dev/null 2>&1 || {
    alias f="exec fish"
}

[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
