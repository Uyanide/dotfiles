#!/bin/sh

LYRICS=$(eww active-windows | grep "lyrics:")
LYRICS_SINGLE=$(eww active-windows | grep "lyrics-single:")

# both are closed
if [ -z "$LYRICS" ] && [ -z "$LYRICS_SINGLE" ]; then
    eww open lyrics

# only lyrics is open
elif [ -n "$LYRICS" ] && [ -z "$LYRICS_SINGLE" ]; then
    eww close lyrics
    sleep 0.5
    eww open lyrics-single

# only lyrics-single is open
elif [ -z "$LYRICS" ] && [ -n "$LYRICS_SINGLE" ]; then
    eww close lyrics-single

# both are open
elif [ -n "$LYRICS" ] && [ -n "$LYRICS_SINGLE" ]; then
    eww close lyrics
    eww close lyrics-single
fi