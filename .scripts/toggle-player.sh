#!/bin/env bash

if [ -n "$(eww active-windows | grep -i "player")" ]; then
  eww close player
elif [ -n "$(pgrep -i "spotify")" ]; then
  eww open player
fi