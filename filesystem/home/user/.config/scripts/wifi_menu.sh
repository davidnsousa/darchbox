#!/bin/bash

selected=$(nmcli -t -f ssid dev wifi | grep -E -v '^$' | eval "dmenu -nb '$(cat $COLORS | grep -w BGCOLOR | awk '{print $2}')' -nf '$(cat $COLORS | grep -w FGCOLOR | awk '{print $2}')' -sb '$(cat $COLORS | grep -w COLOR | awk '{print $2}')' -fn 'DejaVu Sans:size=9.6' -p 'Connect to Wi-FI:' ")

if [[ -n "$selected" ]]; then
	if nmcli -s -g 802-11-wireless-security.psk connection show '$selected' 2>&1 | grep -q "no such connection profile"; then
		$TERMINAL -e nmcli --ask device wifi connect "$selected"
    else
		nmcli device wifi connect "$selected"
	fi
fi

