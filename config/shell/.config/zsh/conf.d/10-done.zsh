# Long command done notification for Niri (Wayland)
# Sends notify-send when a command takes longer than $uy_done_min_cmd_duration
# seconds and the terminal window is not focused.

(( $+commands[notify-send] )) && [[ -n "$NIRI_SOCKET" ]] || return

zmodload zsh/datetime

: ${uy_done_min_cmd_duration:=10}
: ${uy_done_exclude:='^(nvim|helix|hx|vim|vi|nano|less|more|man|ssh|top|htop|btop|sudoedit|yazi)$'}

# Returns the id in $REPLY, empty if there is none or niri did not answer.
if zmodload zsh/net/socket 2>/dev/null; then
    uy_done_get_focused_window_id() {
        setopt local_options extended_glob
        local fd line
        local -a match mbegin mend
        REPLY=

        zsocket "$NIRI_SOCKET" 2>/dev/null || return
        fd=$REPLY
        REPLY=

        if print -u $fd -r -- '"FocusedWindow"' 2>/dev/null; then
            read -t 1 -u $fd -r line 2>/dev/null
        fi
        exec {fd}>&-

        # With no focused window the payload is null, so the id is simply absent.
        [[ $line == (#b)*'"FocusedWindow":'*'"id":'(<->)* ]] && REPLY=$match[1]
    }
elif (( $+commands[jq] )); then
    uy_done_get_focused_window_id() {
        REPLY=$(niri msg --json focused-window 2>/dev/null | jq -r '.id // empty')
    }
else
    return
fi

uy_done_cmd_name() {
    local -a words
    words=(${(z)1})

    while (( $#words )); do
        case $words[1] in
            *=*) ;;
            -*) ;;
            sudo|doas|env|command|builtin|exec|nohup|nice|ionice|time|stdbuf|setsid) ;;
            *) REPLY=${words[1]:t}; return ;;
        esac
        shift words
    done

    # Nothing but wrappers — fall back to the first word.
    REPLY=${1%% *}
}

uy_done_preexec() {
    local REPLY
    uy_done_cmd="$1"
    uy_done_start=$EPOCHSECONDS
    uy_done_get_focused_window_id
    uy_done_window_id=$REPLY
}

uy_done_precmd() {
    local exit_status=$?
    [[ -n "$uy_done_start" ]] || return

    local elapsed=$(( EPOCHSECONDS - uy_done_start ))
    unset uy_done_start

    (( elapsed >= uy_done_min_cmd_duration )) || return

    # skip excluded commands
    local REPLY
    uy_done_cmd_name "$uy_done_cmd"
    [[ "$REPLY" =~ $uy_done_exclude ]] && return

    # skip if window is still focused
    local current_id
    uy_done_get_focused_window_id
    current_id=$REPLY
    [[ -n "$uy_done_window_id" && "$uy_done_window_id" = "$current_id" ]] && return

    # humanize duration
    local title duration="" urgency=low
    local minutes=$(( elapsed / 60 )) seconds=$(( elapsed % 60 ))
    local hours=$(( elapsed / 3600 ))
    (( hours > 0 )) && duration+="${hours}h "
    (( minutes > 0 )) && duration+="$(( minutes % 60 ))m "
    duration+="${seconds}s"

    local wd="${PWD/#$HOME/~}"
    if (( exit_status == 0 )); then
        title="Done in $duration"
    else
        title="Failed ($exit_status) after $duration"
        urgency=critical
    fi

    notify-send \
        --hint=int:transient:1 \
        --urgency="$urgency" \
        --icon=utilities-terminal \
        --app-name=zsh \
        "$title" "$wd/ $uy_done_cmd" & disown
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec uy_done_preexec
add-zsh-hook precmd uy_done_precmd
