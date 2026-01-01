# PATH
fish_add_path $HOME/go/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/scripts
fish_add_path $HOME/.local/bin

# man
if type -q bat
    set -x -g MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -x -g MANROFFOPT -c
end

# Editor
for app in helix nvim vim vi nano
    if type -q $app
        set -x -g EDITOR $app
        set -x -g VISUAL $app
        break
    end
end

# Create shortcut alias for helix
if type -q helix; and not type -q hx
    alias hx helix
end

# gpg
set -x -g GPG_TTY (tty)