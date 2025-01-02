#!/bin/bash

status() {
        connection=$(bluetoothctl show | grep -q "Powered: yes" && echo "On" || echo "Off")
        device=$(bluetoothctl info | grep -q "Connected: yes" && bluetoothctl info | grep -o 'Name:.*' | sed 's/Name: //')
        if [ "$device" != "" ]; then
                echo "%{F#2EBA3B}↑%{F-} $device"
        else
                if [ "$connection" = On ]; then
                        echo "%{F#2EBA3B}↑%{F-}"
                else
                        echo "%{F#FF0000}↓%{F-}"
                fi
        fi
}

toggle() {
        bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on
}

connect() {
        dab -b
}

case $1 in
        "--status") status;;
        "--toggle") toggle;;
        "--connect") connect;;
esac
