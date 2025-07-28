#!/bin/env bash

function close() {
    killall -q waybar

    # Also close the lyrics widget if open
    if eww active-windows | grep -q "lyrics-single"; then
        eww close lyrics-single
    fi
}

function open() {
    # the system tray will not work with kded6 started
    if killall -q "kded6"; then
        while pgrep -x "kded6" >/dev/null; do
            sleep 0.2
        done
    fi
    waybar &
}

if [ -z "$1" ]; then
    close
    while pgrep -x "waybar" >/dev/null; do
        sleep 0.2
    done
    open
elif [ "$1" = "close" ]; then
    if ! pgrep -x "waybar" >/dev/null; then
        exit 1
    fi
    close
elif [ "$1" = "open" ]; then
    if pgrep -x "waybar" >/dev/null; then
        exit 1
    fi
    open
else
    echo "Usage: $0 [close|open]"
    exit 1
fi
