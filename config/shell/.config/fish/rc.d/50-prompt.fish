function fish_prompt -d "Write out the prompt"
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

# oh-my-posh
if test -f $HOME/.config/posh_theme.omp.json; and type -q oh-my-posh
    eval (oh-my-posh init fish --config $HOME/.config/posh_theme.omp.json)
else if type -q starship
    function starship_transient_prompt_func
        starship module character
    end
    eval (starship init fish)
    enable_transience
end
