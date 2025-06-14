fish_add_path $HOME/.local/bin
fish_add_path $HOME/bin

# cargo
if test -f $HOME/.cargo/env.fish
    source $HOME/.cargo/env.fish
end

if test -d $HOME/.scripts
    fish_add_path $HOME/.scripts
end
