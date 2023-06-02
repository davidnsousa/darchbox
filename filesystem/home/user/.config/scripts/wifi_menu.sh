#!/bin/bash

selected=$(nmcli -t -f ssid dev wifi | grep -E -v '^$' | eval "dmenu $DMENU_ARGS -p 'Connect to Wi-FI:' ")

if [[ -n "$selected" ]]; then
	if nmcli -s -g 802-11-wireless-security.psk connection show '$selected' 2>&1 | grep -q "no such connection profile"; then
		$TERMINAL -e nmcli --ask device wifi connect "$selected"
    else
		nmcli device wifi connect "$selected"
	fi
fi

