#!/bin/env bash

function output() {
    jq -n --unbuffered --compact-output \
        --arg alt "$1" \
        --arg class "$2" \
        '{alt: $alt, class: [$class]}'
}

if [ "$1" = "toggle" ]; then
    pid=$(pgrep -x "swayidle")

    if [ -n "$pid" ]; then
        killall swayidle > /dev/null 2>&1
        notify-send "Caffeine enabled" "POWERRR!!!"
    else
        nohup niri-swayidle > /dev/null 2>&1 &
        notify-send "Caffeine disabled" "zzz..."
    fi

    exit 0
fi

# sleep 0.2 # Allow hypridle to start

pid=$(pgrep -x "swayidle")
if [ -n "$pid" ]; then
    output "inactive" "inactive"
else
    output "active" "active"
fi