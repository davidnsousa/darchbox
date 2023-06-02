#!/bin/bash

devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
selection=$(echo "$devices" | eval "dmenu $DMENU_ARGS -p 'Connect to Bluetooth device:'")

if [ -n "$selection" ]; then
    mac=$(echo "$selection" | cut -f1 -d' ')
    echo -e "connect $mac\nquit" | bluetoothctl
fi
