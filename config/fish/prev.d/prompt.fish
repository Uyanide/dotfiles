function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

# oh-my-posh
if test -f $HOME/.config/posh_theme.omp.json; and type -q oh-my-posh
    oh-my-posh init fish --config $HOME/.config/posh_theme.omp.json | source
end