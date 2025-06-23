#!/bin/sh

STATE_DIR="$HOME/.local/state/eww/lyrics"
if [ ! -d $STATE_DIR ]; then
    mkdir -p $STATE_DIR
fi

OFFSET_FILE="$STATE_DIR/offset"
if [ ! -f "$OFFSET_FILE" ]; then
    echo "0" > "$OFFSET_FILE"
fi

spotify-lyrics print -l 3 -O $(cat "$OFFSET_FILE")