#!/bin/bash

connect_disconnect_wifi() {
	nmcli device | grep wifi | awk '{print $3}' | grep -w connected && nmcli device disconnect $WIFIDEVICE || nmcli device connect $WIFIDEVICE
}

toggle_wifi() {
	nmcli radio wifi | grep enabled && nmcli radio wifi off || nmcli radio wifi on
}

toggle_networking() {

	nmcli networking | grep enabled && nmcli networking off || nmcli networking on
}

export -f toggle_wifi
export -f toggle_networking
export -f connect_disconnect_wifi

echo -e "Connect/Disconnect Wi-Fi\nEnable/Disable Wi-Fi\nEnable/Disable Networking" | dmenu -nb '#383c4a' -nf '#ffffff' -sb '#5294e2' -fn 'DejaVu Sans:size=9.6' -p "Network Options:" | xargs -I{} sh -c 'if [ "{}" = "Connect/Disconnect Wi-Fi" ]; then connect_disconnect_wifi; elif [ "{}" = "Enable/Disable Wi-Fi" ]; then toggle_wifi; elif [ "{}" = "Enable/Disable Networking" ]; then toggle_networking; fi'
