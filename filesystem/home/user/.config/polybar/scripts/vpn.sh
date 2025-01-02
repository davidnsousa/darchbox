#!/bin/bash

get_connection_status() {
    connection=$(nmcli connection show --active | grep -q -E "tun0|wg0" && echo "Connected" || echo "Disconnected")
    echo $connection   
}

print_connection_status() {
    if [ "$(get_connection_status)" = "Connected" ]; then
        echo "%{F#2EBA3B}↑%{F-}"
    else
        echo "%{F#FF0000}↓%{F-}"
    fi
}

case $1 in
	"--status") print_connection_status;;
	"--toggle")
	    if [ "$(get_connection_status)" = "Connected" ]; then
	        $(grep 'vpn_disconnect' ~/.config/darchbox/settings | sed 's/^[^ ]* //')
        elif [ "$(get_connection_status)" = "Disconnected" ]; then
	        $(grep 'vpn_connect' ~/.config/darchbox/settings | sed 's/^[^ ]* //')
	    else
            :
	    fi;;
esac
