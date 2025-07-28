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
        notify-send "Caffeine enabled" "POWERRR!!!"
    else
        hyprctl dispatch exec hypridle > /dev/null 2>&1
        notify-send "Caffeine disabled" "zzz..."
    fi
    exit 0
fi

# sleep 0.2 # Allow hypridle to start
pid=$(pgrep -x "hypridle")
if [ -n "$pid" ]; then
    output "inactive" "inactive"
else
    output "active" "active"
fi