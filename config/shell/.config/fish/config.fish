if not status is-interactive
    return
end

# no greeting
set fish_greeting

for f in $__fish_config_dir/rc.d/*.fish
    source $f
end
