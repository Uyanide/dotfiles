# Long command done notification for Niri (Wayland)
# Sends notify-send when a command takes longer than $uy_done_min_cmd_duration
# seconds and the terminal window is not focused.

(( $+commands[notify-send] )) && [[ -n "$NIRI_SOCKET" ]] || return

zmodload zsh/datetime

: ${uy_done_min_cmd_duration:=10}
: ${uy_done_exclude:='^(nvim|helix|hx|vim|vi|nano|less|more|man|ssh|top|htop|btop)$'}

uy_done_get_focused_window_id() {
	(( $+commands[jq] )) || return
	niri msg --json focused-window 2>/dev/null | jq -r '.id // empty'
}

uy_done_preexec() {
	uy_done_cmd="$1"
	uy_done_start=$EPOCHSECONDS
	uy_done_window_id=$(uy_done_get_focused_window_id)
}

uy_done_precmd() {
	local exit_status=$?
	[[ -n "$uy_done_start" ]] || return

	local elapsed=$(( EPOCHSECONDS - uy_done_start ))
	unset uy_done_start

	(( elapsed >= uy_done_min_cmd_duration )) || return

	# skip excluded commands
	local cmd_name="${uy_done_cmd%% *}"
	[[ "$cmd_name" =~ $uy_done_exclude ]] && return

	# skip if window is still focused
	local current_id
	current_id=$(uy_done_get_focused_window_id)
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
		"$title" "$wd/ $uy_done_cmd"
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec uy_done_preexec
add-zsh-hook precmd uy_done_precmd
