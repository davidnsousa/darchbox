#!/bin/bash

devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
selection=$(echo "$devices" | dmenu -nb '#383c4a' -nf '#ffffff' -sb '#5294e2' -fn 'DejaVu Sans:size=9.6' -p "Connect to Bluetooth device:")

if [ -n "$selection" ]; then
    mac=$(echo "$selection" | cut -f1 -d' ')
    echo -e "connect $mac\nquit" | bluetoothctl
fi
