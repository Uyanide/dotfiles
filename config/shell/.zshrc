#!/hint/zsh

[[ $- != *i* ]] && return

for _f in "${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/conf.d/*.zsh(N); do
	source "$_f"
done
unset _f
