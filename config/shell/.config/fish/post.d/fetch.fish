if not set -q fetch_logo_type
    set -g fetch_logo_type auto
end

if ps -e -o pid,comm | grep -q (pgrep kmscon)
    set -g fetch_logo_type logo
end

if not set -q fetch_color
    set -g fetch_color "#89b4fa"
end

if test "$fetch_logo_type" = symbols
    set -g fetch_args "--logo-type raw --logo-width 42 --logo \"$HOME/.config/fastfetch/logo_ros/42x.symbols\" --color \"$fetch_color\""
    set -g fetch_args_brief "--logo-type raw --logo-width 28 --logo \"$HOME/.config/fastfetch/logo_ros/28x.symbols\" --color \"$fetch_color\""
else if test "$fetch_logo_type" = logo
    set -g fetch_args "--logo-type builtin"
    set -g fetch_args_brief "--logo-type small"
else if test "$fetch_logo_type" = sixel
    set -g fetch_args "--logo-type raw --logo-width 42 --logo \"$HOME/.config/fastfetch/logo_ros/42x.sixel\" --color \"$fetch_color\""
    set -g fetch_args_brief "--logo-type raw --logo-width 28 --logo \"$HOME/.config/fastfetch/logo_ros/28x.sixel\" --color \"$fetch_color\""
else # "kitty" or "auto" and others
    set -g fetch_args "--logo-type $fetch_logo_type --logo-width 42 --logo \"$HOME/.config/fastfetch/logo_ros/ros.png\" --color \"$fetch_color\""
    set -g fetch_args_brief "--logo-type $fetch_logo_type --logo-width 28 --logo \"$HOME/.config/fastfetch/logo_ros/ros.png\" --color \"$fetch_color\""
end

if type -q fastfetch
    alias ff="fastfetch -c $HOME/.config/fastfetch/config.jsonc $fetch_args"

    if test -f "$HOME/.config/fastfetch/brief.jsonc"
        alias ffb="fastfetch -c $HOME/.config/fastfetch/brief.jsonc $fetch_args_brief"
    else
        alias ffb=ff
    end
end

# add 'set -g no_fetch' somewhere other than post.d to disable fetching
if not set -q no_fetch
    if type -q ffb
        ffb
    end
end
