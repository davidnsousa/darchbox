#!/bin/bash

selected=$(nmcli -t -f ssid dev wifi | grep -E -v '^$' | dmenu -nb '#383c4a' -nf '#ffffff' -sb '#5294e2' -fn 'DejaVu Sans:size=9.6' -p "Connect to Wi-FI:")

if [[ -n "$selected" ]]; then
  $TERMINAL -e nmcli device wifi connect "$selected"
fi
