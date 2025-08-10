#!/bin/sh

if [ "$(id -u)" -eq 0 ]; then
    exit 0
fi

if [ -n "$SUDO_USER" ]; then
    exit 0
fi

if [ "$LOGNAME" != "$USER" ]; then
    exit 0
fi

ppid=$(ps -o ppid= -p $$ 2>/dev/null)
if [ -n "$ppid" ]; then
    parent_comm=$(ps -o comm= -p "$ppid" 2>/dev/null)
    if [ "$parent_comm" = "su" ]; then
        exit 0
    fi
fi

exit 1