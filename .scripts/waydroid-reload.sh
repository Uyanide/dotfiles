#!/bin/env bash

function checkReturn {
    echo "Executing: $@"
    if ! "$@"; then
        echo "Error runnning command"
        exit 1
    fi
}

checkReturn waydroid session stop
# checkReturn sudo waydroid upgrade # since I'm not using the default image
checkReturn sudo waydroid init -f
checkReturn sudo systemctl restart waydroid-container
checkReturn waydroid show-full-ui
