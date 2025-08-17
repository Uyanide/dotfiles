if not status is-interactive
    return
end

# no greeting
set fish_greeting

# ls alias
alias ls="ls --hyperlink=auto --color=auto"
alias ll="ls -lh"
alias la="ls -lha"

# grep alias
alias grep="grep --color=auto"

# nvim
if type -q nvim
    set -x EDITOR nvim
    set -x VISUAL nvim
end

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
