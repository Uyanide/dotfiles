# PATH
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.scripts

# man
if type -q bat
    set -x -g MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -x -g MANROFFOPT -c
end