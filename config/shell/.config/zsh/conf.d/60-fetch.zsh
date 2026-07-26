# Detect logo capability.

_uy_fetch_probe() {
    if (( $+commands[kgp-query] )) && kgp-query 2>/dev/null; then
        uy_fetch_logo_type=kitty
    elif (( $+commands[sixel-query] )) && sixel-query 2>/dev/null; then
        uy_fetch_logo_type=sixel
    elif (( $+commands[kgp-query] )) || (( $+commands[sixel-query] )); then
        uy_fetch_logo_type=logo
    else
        uy_fetch_logo_type=auto
    fi
}

if [[ -z "$uy_fetch_logo_type" ]]; then
    if [[ -t 0 ]] && (( $+commands[kgp-query] || $+commands[sixel-query] )); then
        _uy_fetch_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/logo-type"
        # Terminal identity, sanitised down to a single path component
        _uy_fetch_cache_file="$_uy_fetch_cache_dir/${${TERM:-none}//[^A-Za-z0-9._-]/_}@${${TERM_PROGRAM:-none}//[^A-Za-z0-9._-]/_}"

        [[ -s "$_uy_fetch_cache_file" ]] && uy_fetch_logo_type="$(<"$_uy_fetch_cache_file")"

        # Covers both a cache miss and a cache file holding anything unexpected
        if [[ "$uy_fetch_logo_type" != (kitty|sixel|logo|symbols|auto) ]]; then
            _uy_fetch_probe
            [[ -d "$_uy_fetch_cache_dir" ]] || mkdir -p "$_uy_fetch_cache_dir"
            print -r -- "$uy_fetch_logo_type" >| "$_uy_fetch_cache_file"
        fi

        unset _uy_fetch_cache_dir _uy_fetch_cache_file
    else
        _uy_fetch_probe
    fi
fi

unfunction _uy_fetch_probe

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
unicode)
    uy_fetch_args=(--logo-type raw --logo-width 42 --logo "$HOME/.config/fastfetch/logo_ros/42x.unicode" --color "$uy_fetch_color")
    uy_fetch_args_brief=(--logo-type raw --logo-width 28 --logo "$HOME/.config/fastfetch/logo_ros/28x.unicode" --color "$uy_fetch_color")
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
