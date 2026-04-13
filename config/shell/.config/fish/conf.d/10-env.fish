# PATH is managed by .bash_profile

# man
if type -q bat
    set -x -g MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -x -g MANROFFOPT -c
end

# Editor
for app in nvim helix vim vi nano
    if type -q $app
        set -x -g EDITOR $app
        set -x -g VISUAL $app
        break
    end
end

# Create shortcut alias for helix
if type -q helix; and not type -q hx
    alias hx helix
end

# gpg
set -x -g GPG_TTY (tty)

# done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

# fnm
if type -q fnm
    fnm env --shell fish --use-on-cd | source
end
