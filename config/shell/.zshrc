# lrx completions
fpath=(/home/kolkas/.zsh/completions $fpath)
#!/hint/zsh

[[ $- != *i* ]] && return


for _f in "${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/conf.d/*.zsh(N); do
	source "$_f"
done

for _f in "${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/funcs.d/*.zsh(N); do
	source "$_f"
done

for _f in "${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/funcs.d/_*(N); do
	source "$_f"
done


unset _f
