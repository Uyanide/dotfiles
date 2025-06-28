#!/bin/env bash

HIGHLIGHT_COLOR="#cdd6f4" # text
NORMAL_COLOR="#7f849c" # overlay1
TARGET_LINE=1
[ -n $1 ] && TARGET_LINE="$1"

mapfile -t lines

output=""
for i in "${!lines[@]}"; do
    line_num=$((i + 1))
    escaped_line=$(echo "${lines[$i]}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    [[ $i -gt 0 ]] && output+=$'\n' # +="\n" is not properly displayed in eww

    if [[ $line_num -eq $TARGET_LINE ]]; then
        output+="<span color=\"$HIGHLIGHT_COLOR\">$escaped_line</span>"
    else
        output+="<span color=\"$NORMAL_COLOR\">$escaped_line</span>"
    fi
done

echo "$output"