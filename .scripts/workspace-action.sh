#!/usr/bin/env bash
# https://github.com/end-4/dots-hyprland/blob/main/.config/ags/scripts/hyprland/workspace_action.sh

hyprctl dispatch "$1" $(((($(hyprctl activeworkspace -j | jq -r .id) - 1)  / 10) * 10 + $2))