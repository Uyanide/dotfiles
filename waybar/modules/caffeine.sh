#!/bin/env bash

function output() {
    jq -n --unbuffered --compact-output \
        --arg alt "$1" \
        --arg class "$2" \
        '{alt: $alt, class: [$class]}'
}

if [ -n "$1" ]; then
    pid=$(pgrep -x "hypridle")
    if [ -n "$pid" ]; then
        killall hypridle > /dev/null 2>&1
    else
        hyprctl dispatch exec hypridle > /dev/null 2>&1
    fi
    exit 0
fi

sleep 0.3 # Allow hypridle to start
pid=$(pgrep -x "hypridle")
if [ -n "$pid" ]; then
    output "inactive" "inactive"
    notify-send "Caffeine disabled" "Caffeine mode is now inactive."
else
    output "active" "active"
    notify-send "Caffeine enabled" "Caffeine mode is now active."
fi