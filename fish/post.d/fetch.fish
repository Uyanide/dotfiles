if not set -q fetch_logo_type
    set -g fetch_logo_type "auto"
end

if test "$fetch_logo_type" = "symbols"
    set -g fetch_args "--logo-type raw --logo-width 42 --logo \"$HOME/.config/fastfetch/logo_ros/42x.symbols\" --color \"#74c7ec\""
    set -g fetch_args_brief "--logo-type raw --logo-width 24 --logo \"$HOME/.config/fastfetch/logo_ros/24x.symbols\" --color \"#74c7ec\""
else if test "$fetch_logo_type" = "logo"
    set -g fetch_args "--logo-type builtin"
    set -g fetch_args_brief "--logo-type small"
else if test "$fetch_logo_type" = "sixel"
    set -g fetch_args "--logo-type raw --logo-width 42 --logo \"$HOME/.config/fastfetch/logo_ros/42x.sixel\" --color \"#74c7ec\""
    set -g fetch_args_brief "--logo-type raw --logo-width 24 --logo \"$HOME/.config/fastfetch/logo_ros/24x.sixel\" --color \"#74c7ec\""
else # "kitty" or "auto" and others
    set -g fetch_args "--logo-type $fetch_logo_type --logo-width 42 --logo \"$HOME/.config/fastfetch/logo_ros/ros.png\" --color \"#74c7ec\""
    set -g fetch_args_brief "--logo-type $fetch_logo_type --logo-width 24 --logo \"$HOME/.config/fastfetch/logo_ros/ros.png\" --color \"#74c7ec\""
end

if type -q fastfetch
    alias ff="fastfetch -c $HOME/.config/fastfetch/config.jsonc $fetch_args"

    if test -f "$HOME/.config/fastfetch/brief.jsonc"
        alias ff-brief="fastfetch -c $HOME/.config/fastfetch/brief.jsonc $fetch_args_brief"
    else
        alias ff-brief=ff
    end
end

# add 'set -g no_fetch' somewhere other than post.d to disable fetching
if not set -q no_fetch
    if type -q ff-brief
	    ff-brief
    end
end
