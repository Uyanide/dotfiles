#!/bin/sh

killall spotify-lyrics
sleep 0.1
spotify-lyrics clear
notify-send -a "spotify-lyrics" "Lyrics Cleared" "The lyrics have been cleared."