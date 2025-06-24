if type -q fzf
    fzf --fish | source
end

if type -q zoxide
    zoxide init fish | source
    alias cd=z
end
