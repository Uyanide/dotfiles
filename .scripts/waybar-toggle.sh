#!/bin/env bash

function close() {
    if pgrep -x "waybar" > /dev/null; then
        killall -q waybar

        # Wait until the processes have been shut down
        while pgrep -x waybar >/dev/null; do sleep 1; done
    fi
}

function open() {
    waybar &
}

if [ -z "$1" ]; then
    close
    open
elif [ "$1" = "close" ]; then
    if ! pgrep -x "waybar" > /dev/null; then
        exit 1
    fi
    close
elif [ "$1" = "open" ]; then
    if pgrep -x "waybar" > /dev/null; then
        exit 1
    fi
    open
else
    echo "Usage: $0 [close|open]"
    exit 1
fi