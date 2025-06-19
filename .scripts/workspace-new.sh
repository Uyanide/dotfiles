#!/bin/bash

# get highest workspace ID
max_id=$(hyprctl workspaces | grep '^workspace ID ' | awk '{print $3}' | sort -n | tail -1)

# case not found default to 0
if [ -z "$max_id" ]; then
    max_id=0
fi

hyprctl dispatch workspace $((max_id + 1))