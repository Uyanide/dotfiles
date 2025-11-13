# PATH
fish_add_path $HOME/.local/scripts
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/go/bin

# man
if type -q bat
    set -x -g MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -x -g MANROFFOPT -c
end

# nvim
if type -q nvim
    set -x -g EDITOR nvim
    set -x -g VISUAL nvim
end

# gpg
set -x -g GPG_TTY (tty)