# Detect logo capability

if [[ -z "$uy_fetch_logo_type" ]]; then
	if (( $+commands[kgp-query] )) && kgp-query 2>/dev/null; then
		uy_fetch_logo_type=kitty
	elif (( $+commands[sixel-query] )) && sixel-query 2>/dev/null; then
		uy_fetch_logo_type=sixel
	elif (( $+commands[kgp-query] )) || (( $+commands[sixel-query] )); then
		uy_fetch_logo_type=logo
	else
		uy_fetch_logo_type=auto
	fi
fi

: ${uy_fetch_color:="38;2;137;180;250"}

# Build fastfetch args (arrays to handle paths with spaces safely)

case "$uy_fetch_logo_type" in
symbols)
	uy_fetch_args=(--logo-type raw --logo-width 42 --logo "$HOME/.config/fastfetch/logo_ros/42x.symbols" --color "$uy_fetch_color")
	uy_fetch_args_brief=(--logo-type raw --logo-width 28 --logo "$HOME/.config/fastfetch/logo_ros/28x.symbols" --color "$uy_fetch_color")
	;;
logo)
	uy_fetch_args=(--logo-type builtin)
	uy_fetch_args_brief=(--logo-type small)
	;;
sixel)
	uy_fetch_args=(--logo-type raw --logo-width 42 --logo "$HOME/.config/fastfetch/logo_ros/42x.sixel" --color "$uy_fetch_color")
	uy_fetch_args_brief=(--logo-type raw --logo-width 28 --logo "$HOME/.config/fastfetch/logo_ros/28x.sixel" --color "$uy_fetch_color")
	;;
*) # kitty, auto, etc.
	uy_fetch_args=(--logo-type "$uy_fetch_logo_type" --logo-width 42 --logo "$HOME/.config/fastfetch/logo_ros/ros.png" --color "$uy_fetch_color")
	uy_fetch_args_brief=(--logo-type "$uy_fetch_logo_type" --logo-width 28 --logo "$HOME/.config/fastfetch/logo_ros/ros.png" --color "$uy_fetch_color")
	;;
esac

# Functions

if (( $+commands[fastfetch] )); then
	ff() { fastfetch -c "$HOME/.config/fastfetch/config.jsonc" "${uy_fetch_args[@]}" "$@"; }

	if [[ -f "$HOME/.config/fastfetch/brief.jsonc" ]]; then
		ffb() { fastfetch -c "$HOME/.config/fastfetch/brief.jsonc" "${uy_fetch_args_brief[@]}" "$@"; }
	else
		ffb() { ff "$@"; }
	fi
fi

# Auto-fetch on startup

if [[ -z "$uy_no_fetch" ]] && (( $+functions[ffb] )); then
	ffb
fi
