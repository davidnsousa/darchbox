#!/bin/bash

status() {
        WIFIDEVICE=$(nmcli device status | awk '$2=="wifi"{print $1}')
        connection=$(nmcli -t -f type,device,state connection show | grep wireless | grep activated > /dev/null && echo "up" || echo "down")
        ssid=$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | cut -d: -f2)
        adress=$(ip -4 address show dev $WIFIDEVICE | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d/ -f1)
        signal=$(nmcli -f IN-USE,SIGNAL device wifi | grep \* | awk '{print $2}')
        if [ "$connection" = "up" ]; then
                echo "%{F#2EBA3B}↑%{F-} $signal% $ssid $adress"
        else
                if [ "$(nmcli networking | grep enabled)" = "enabled" ] && [ "$(nmcli radio wifi | grep enabled)" = "enabled" ]; then
                        echo "%{F#2EBA3B}↑%{F-}"
                else
                        echo "%{F#FF0000}↓%{F-}"
                fi
fi
}

toogle_bluetooth() {
        bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on
}

connect() {
        dab -w
}

network_settings() {
        dab -n
}

case $1 in
        "--status") status;;
        "--networksettings") network_settings;;
        "--connect") connect;;
esac
