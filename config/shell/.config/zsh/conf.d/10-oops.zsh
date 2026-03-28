# Remove the last command from history (both memory and file).
# The alias has a leading space so "oops" itself is not recorded (HIST_IGNORE_SPACE).
uy_oops_confirm() {
	# Flush current session to file so we operate on the latest state
	fc -W

	if [[ ! -f "$HISTFILE" || ! -s "$HISTFILE" ]]; then
		print -P "%F{yellow}History is empty, nothing to delete.%f"
		return 1
	fi

	# Read the last entry (may span multiple lines if it ends with \)
	local -a entry
	local line
	while IFS= read -r line; do
		entry+=("$line")
		# EXTENDED_HISTORY continuation lines end with a literal backslash
		[[ "$line" == *'\' ]] || break
	done < <(tail -n 50 "$HISTFILE" | tac)
	# entry is reversed (last line first), flip it back
	local -a ordered
	for (( i=${#entry[@]}; i>=1; i-- )); do
		ordered+=("${entry[$i]}")
	done

	if (( ${#ordered[@]} == 0 )); then
		print -P "%F{yellow}Could not parse last history entry.%f"
		return 1
	fi

	print -P "About to permanently delete the last command from history:"
	for line in "${ordered[@]}"; do
		print -P "  %F{red}${line}%f"
	done

	local reply
	echo -n "Proceed? [Y/n] "
	read -r reply

	if [[ -z "$reply" || "$reply" == [yY]* ]]; then
		# Delete the last N lines (the full entry) from the file
		local n=${#ordered[@]}
		head -n -"$n" "$HISTFILE" > "$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
		# Reload history from the updated file
		fc -R
		print -P "%F{green}Deleted ($n line(s) removed).%f"
	else
		# Reload anyway to stay in sync
		fc -R
		print -P "%F{yellow}Cancelled.%f"
	fi
}

alias oops=' uy_oops_confirm'
