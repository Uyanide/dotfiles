# Remove the last command from history (both memory and file).
#
# NOTE: other shells running concurrently still hold the entry in their own
# in-memory history and can write it back; SHARE_HISTORY does not propagate
# deletions.

uy_oops_confirm() {
    # Flush current session to file so we operate on the latest state
    fc -W

    if [[ ! -f "$HISTFILE" || ! -s "$HISTFILE" ]]; then
        print -P "%F{yellow}History is empty, nothing to delete.%f"
        return 1
    fi

    # Find where the last entry starts. An entry continues onto the next line
    # when the current one ends in a backslash; zsh writes a command that itself
    # ends in a backslash as "\ " (trailing space), so the marker is unambiguous.
    # Walking forward and remembering the start of each entry is exact for
    # entries of any length.
    local start
    start=$(awk '{ if (!cont) start = NR; cont = /\\$/ } END { print start + 0 }' "$HISTFILE")

    if [[ -z "$start" ]] || (( start < 1 )); then
        print -P "%F{yellow}Could not parse last history entry.%f"
        return 1
    fi

    local -a ordered
    ordered=("${(@f)$(tail -n +"$start" "$HISTFILE")}")

    if (( ${#ordered[@]} == 0 )); then
        print -P "%F{yellow}Could not parse last history entry.%f"
        return 1
    fi

    local line
    print -P "About to permanently delete the last command from history:"
    for line in "${ordered[@]}"; do
        print -P "  %F{red}${line}%f"
    done

    local reply
    echo -n "Proceed? [Y/n] "
    read -r reply

    if [[ -z "$reply" || "$reply" == [yY]* ]]; then
        # Keep everything before the entry. start-1 == 0 (the entry is the only
        # one) correctly leaves an empty file.
        local n=${#ordered[@]}
        head -n $(( start - 1 )) "$HISTFILE" > "$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
        # Replace the in-memory history with the updated file. `fc -p` is the
        # only primitive that replaces it: `fc -R` *appends* the file on top of
        # what is already in memory, which both duplicates every entry and
        # leaves the deleted command there for the next `fc -W` to write back.
        #
        # `fc -p` pushes a history layer, and each layer retains a full copy of
        # the history, so pop the layer the previous call left behind first —
        # that keeps exactly one live no matter how often `oops` runs. `fc -P`
        # only restores the old in-memory list, it does not write to $HISTFILE,
        # so it cannot undo the deletion above; and the push on the very next
        # line replaces that stale list immediately. Both must stay in this
        # branch: on the cancel path nothing was deleted, so memory already
        # matches the file and popping would corrupt it.
        fc -P 2>/dev/null
        fc -p "$HISTFILE" $HISTSIZE $SAVEHIST
        print -P "%F{green}Deleted ($n line(s) removed).%f"
    else
        # Nothing was modified, so there is nothing to reload.
        print -P "%F{yellow}Cancelled.%f"
    fi
}

# The alias has a leading space so "oops" itself is not recorded (HIST_IGNORE_SPACE).
alias oops=' uy_oops_confirm'
