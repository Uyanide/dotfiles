#!/bin/sh

killall spotify-lyrics
sleep 0.1
"$HOME/.local/bin/spotify-lyrics" clear
notify-send -a "spotify-lyrics" "Cache Cleared" "The lyrics cache have been cleared."