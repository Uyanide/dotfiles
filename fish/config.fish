if not status is-interactive
    return
end

# no greeting
set fish_greeting

if test -d $HOME/.config/fish/prev.d
    for file in $HOME/.config/fish/prev.d/*.fish
        if test -f $file
            source $file
        end
    end
end

if test -d $HOME/.config/fish/post.d
    for file in $HOME/.config/fish/post.d/*.fish
        if test -f $file
            source $file
        end
    end
end
