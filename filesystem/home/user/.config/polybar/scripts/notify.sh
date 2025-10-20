#!/bin/bash

print_notifications_status() {
    paused=$(dunstctl is-paused)
    if [ "$paused" = "true" ]; then
        echo "%{F#FF0000}↓%{F-}"
    else
        echo "%{F#2EBA3B}↑%{F-}"
    fi
}

toggle() {
    paused=$(dunstctl is-paused)
    if [ "$paused" = "true" ]; then
        dunstctl set-paused false
    else
        dunstctl set-paused true
    fi
}

case $1 in
	"--status") print_notifications_status;;
	"--toggle") toggle;;
esac
