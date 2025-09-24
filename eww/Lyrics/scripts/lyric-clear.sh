#!/bin/sh

if [ -z "$1" ]; then
    "spotify-lyrics" clear
    notify-send -a "spotify-lyrics" "Cache Cleared" "Lyrics cache have been cleared."
else
    "spotify-lyrics" clear "$1"
    notify-send -a "spotify-lyrics" "Cache Cleared" "Lyrics cache for track $1 have been cleared."
fi