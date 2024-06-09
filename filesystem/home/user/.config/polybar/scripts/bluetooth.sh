#!/bin/bash

status() {
        connection=$(bluetoothctl show | grep -q "Powered: yes" && echo "On" || echo "Off")
        device=$(bluetoothctl info | grep -q "Connected: yes" && bluetoothctl info | grep -o 'Name:.*' | sed 's/Name: //')
        if [ "$device" != "" ]; then
                echo "$device"
        else
                echo "$connection"
        fi
}

toogle_bluetooth() {
        bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on
}

connect() {
        darchbox --bluetooth
}

case $1 in
        "--status") status;;
        "--toggle") toogle_bluetooth;;
        "--connect") connect;;
esac
