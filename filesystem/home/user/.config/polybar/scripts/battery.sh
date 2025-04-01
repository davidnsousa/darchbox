#!/bin/bash

status () {
        BATDEVICE=$(echo /sys/class/power_supply/$(ls /sys/class/power_supply/ | grep BAT))
        capacity=$(cat "$BATDEVICE/capacity")
        status=$(cat "$BATDEVICE/status")
        if [ -z "$capacity" ] || [ -z "$status" ]; then
            echo "Error: Unable to retrieve battery information."
            exit 1
        fi

        if [ "$status" = "Charging" ]; then
            echo "%{F#FFFF00}↑%{F-} $capacity%"
        elif [ "$status" = "Not charging" ]; then
            echo "%{F#FFFF00}-%{F-}"
        elif [ "$status" = "Discharging" ] || [ "$status" = "Not Charging" ]; then
            if [ "$capacity" -le 10 ]; then
                echo "%{F#FF0000}↓ $capacity%%{F-}"
            elif [ "$capacity" -le 20 ]; then
                echo "%{F#FFA500}↓ $capacity%%{F-}"
            else
                echo "↓ $capacity%"
            fi
        else
            echo "Unknown status: $status"
        fi
}

case $1 in
        "--status") status;;
esac
