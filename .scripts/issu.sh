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

ppid=$(ps -o ppid= -p $$ 2>/dev/null)
if [ -n "$ppid" ]; then
    parent_comm=$(ps -o comm= -p "$ppid" 2>/dev/null)
    if [ "$parent_comm" = "su" ]; then
        exit 1
    fi
fi
