if test -n "$XDG_CURRENT_DESKTOP"; and test "$XDG_CURRENT_DESKTOP" = "niri"
    set -l env_config "$HOME/.config/niri/config/envs.kdl"

    if test -f "$env_config"
        while read -la line
            # Remove comments
            set line (string replace -r '//.*' '' -- "$line")
            # Trim whitespace
            set line (string trim -- "$line")
            # Skip "environment" block lines
            if test -z "$line"; or string match -q "environment*" -- "$line"; or test "$line" = "}"
                continue
            end
            # Match lines like: VARIABLE "value" where VARIABLE is alphanumeric/underscore
            set -l matches (string match -r '^([0-9A-Za-z_]+)\s+"(.*)"$' -- "$line")
            # If have a matches, set the environment variable
            if test (count $matches) -eq 3
                set -xg $matches[2] $matches[3]
            end
        end < "$env_config"
    end
end
