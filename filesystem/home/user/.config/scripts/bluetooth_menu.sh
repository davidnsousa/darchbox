#!/bin/bash

devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
selection=$(echo "$devices" | eval "dmenu -nb '$(cat $COLORS | grep -w BGCOLOR | awk '{print $2}')' -nf '$(cat $COLORS | grep -w FGCOLOR | awk '{print $2}')' -sb '$(cat $COLORS | grep -w COLOR | awk '{print $2}')' -fn 'DejaVu Sans:size=9.6' -p 'Connect to Bluetooth device:'")

if [ -n "$selection" ]; then
    mac=$(echo "$selection" | cut -f1 -d' ')
    echo -e "connect $mac\nquit" | bluetoothctl
fi
