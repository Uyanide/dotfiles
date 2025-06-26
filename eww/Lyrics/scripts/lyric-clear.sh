#!/bin/sh

if [ -z $1 ]; then
    "$HOME/.local/bin/spotify-lyrics" clear
    notify-send -a "spotify-lyrics" "Cache Cleared" "Lyrics cache have been cleared."
else
    "$HOME/.local/bin/spotify-lyrics" clear "$1"
    notify-send -a "spotify-lyrics" "Cache Cleared" "Lyrics cache for track $1 have been cleared."
fi