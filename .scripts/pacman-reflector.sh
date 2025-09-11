#!/usr/bin/env bash

[ -z "$COUNTRY" ] && COUNTRY="Germany"

sudo cp -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak || exit 1

sudo reflector --country "$COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
