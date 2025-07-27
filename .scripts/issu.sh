#!/bin/sh

if [ "$(id -u)" -eq 0 ]; then
    exit 1
fi

if [ -n "$SUDO_USER" ]; then
    exit 1
fi

if [ "$LOGNAME" != "$USER" ]; then
    exit 1
fi

if [ "$(ps -o comm= -p $(ps -o ppid= -p $$) 2>/dev/null)" = "su" ]; then
    exit 1
fi
