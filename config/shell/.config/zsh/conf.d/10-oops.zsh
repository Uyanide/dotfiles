uy_oops_confirm() {
    if [[ ! -f "$HISTFILE" ]]; then
        print -P "%F{red}Failed to locate history file: $HISTFILE%f"
        return 1
    fi

    local last_line=$(tail -n 1 "$HISTFILE")

    if [[ -z "$last_line" ]]; then
        print -P "%F{yellow}History file is empty, nothing to clean. %f"
        return 0
    fi

    print -P "About to permanently delete the last command from history:"
    print -P "%F{red}  $last_line%f"

    local reply
    echo -n "Proceed? [Y/n] "
    read -r reply

    if [[ -z "$reply" || "$reply" == [yY]* ]]; then
        sed -i '$d' "$HISTFILE"
        print -P "%F{green}Command removed from history.%f"
    else
        print -P "%F{yellow}Operation cancelled.%f"
    fi
}

alias oops=' uy_oops_confirm'
