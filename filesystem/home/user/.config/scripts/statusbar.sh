#!/bin/bash

BGCOLOR=$(cat $COLORS | grep -w BGCOLOR | awk '{print $2}')

system_kernel() {
	echo "$(uname -r)"
}

check_for_arch_updates() {
	test -e ~/.nupdates && nupdates=$(cat ~/.nupdates)
	test -e ~/.nupdates && if [ "$nupdates" != 0 ]; then
		out="%{F#06cf00} \uf021%{F-} $nupdates"
	fi
	
	echo "%{A:$TERMINAL -e yay && bash $XDG_CONFIG_HOME/scripts/check_for_updates.sh &:}$out%{A}"
}

check_for_de_updates() {
	test -e ~/.update_de && out="%{F#e013a4} \uf021%{F-}"
	
	echo "%{A:bash $XDG_CONFIG_HOME/scripts/update_de.sh && bash $XDG_CONFIG_HOME/scripts/check_for_updates.sh &:}$out%{A}"
}

monitors() {
	primary_monitor=$(xrandr --listmonitors | tail -n +2 | grep '*' | awk '{print $NF}')
	if [ $(xrandr | grep $HDMI | awk '{print $2}') = 'connected' ]; then
		if [ $primary_monitor != $HDMI ]; then
			out=" \uf390"
		elif [ $primary_monitor = $HDMI ]; then
			out=" \uf109"
		fi
	fi
	echo "%{A:bash $XDG_CONFIG_HOME/scripts/change_monitor.sh &:} $out%{A}"
}

my_uptime() {
	hours=$(uptime | awk '{print $3}' | tr -d ',')
	out=" \uf64a $hours"
	echo $out
}

load() {
	values=$(uptime | awk -F 'load average: ' '{print $2}' | tr -d ',')
	value_15min=$(uptime | awk -F 'load average: ' '{print $2}' | awk -F ', ' '{print $3}')
	value_15min=${value_15min%.*}
	if [ $value_15min -lt 1 ]; then
        out="%{F#06cf00}\ue473%{F-} $values"
	elif [ $value_15min -ge 1 ] && [ $value_15min -lt 2 ]; then
		out="%{F#ffec00}\ue473%{F-} $values"
    else
        out="%{F#FF0000}\ue473%{F-} $values"
    fi
    echo $out
}

sound_volume() {
	volume=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print $5}' | sed 's/%//')
	pactl list sinks | grep "Active Port" | grep -q headphones && port="\uf025" || if [ $volume -ge 50 ]; then
		port="\uf028"
	else
		port="\uf027"
	fi
	pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && port="%{F#FF0000}$port%{F-}"
	out="$port $volume%"
	echo "%{A3:pactl set-sink-mute @DEFAULT_SINK@ toggle &:}%{A:$CTRLSOUND &:}$out %{A}%{A3}"
}

backlight() {
	value=$(light -G | sed 's/\..*//')
	out="\uf0eb $value%"
	echo $out
}

mem() {
	usage=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')
	usage=${usage%.*}
	if [ $usage -le 50 ]; then
        out="%{F#06cf00}\uf1c0%{F-} $usage%"
	elif [ $usage -gt 50 ] && [ $usage -le 80 ]; then
		out="%{F#ffec00}\uf1c0%{F-} $usage%"
    else
        out="%{F#FF0000}\uf1c0%{F-} $usage%"
    fi
    echo "%{A:$TERMINAL -e htop &:}$out %{A}"
}

swap() {
    usage=$(free -m | awk 'NR==3{printf "%.1f%%", $3*100/$2 }')
    usage=${usage%.*}
    if [ "$usage" -le 50 ]; then
        out="%{F#06cf00}\uf362%{F-} $usage%"
    elif [ "$usage" -gt 50 ] && [ "$usage" -le 80 ]; then
        out="%{F#ffec00}\uf362%{F-} $usage%"
    else
        out="%{F#FF0000}\uf362%{F-} $usage%"
    fi
    echo "%{A:$TERMINAL -e htop &:}$out %{A}"
}


cpu() {
    usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
	if [ $usage -le 50 ]; then
        out="%{F#06cf00}\uf2db%{F-} $usage%"
	elif [ $usage -gt 50 ] && [ $usage -le 80 ]; then
		out="%{F#ffec00}\uf2db%{F-} $usage%"
    else
        out="%{F#FF0000}\uf2db%{F-} $usage%"
    fi
    echo "%{A:$TERMINAL -e htop &:}$out %{A}"
}

disk() {
	usage=$(df -x tmpfs -x devtmpfs -x devfs -h / | awk '{print $5}' | tail -n1)
	out="\uf51f $usage%"
	echo "%{A:$TERMINAL -e htop &:}$out %{A}"
}

battery() {
    capacity=$(cat $BATDEVICE/capacity)
    status=$(cat $BATDEVICE/status | grep -q 'Charging\|Full' && echo "↑" || echo "↓")
    if [ $capacity -lt 10 ] &&  [ $status = '↓' ]; then
        out="%{F#FF0000}\uf244%{F-} $capacity%"
	elif [ $status = '↑' ]; then
		out="%{F#ffec00}\uf1e6%{F-} $capacity%"
    else
        out="\uf242$capacity%"
    fi
    echo $out
}

bluetooth() {
	connection=$(bluetoothctl show | grep -q "Powered: yes" && echo "↑" || echo "↓")
	device=$(bluetoothctl info | grep -q "Connected: yes" && bluetoothctl info | grep -o 'Name:.*' | sed 's/Name: //')
	if [ $(bluetoothctl info | grep "Connected" | awk '{print $2}') ]; then
		out="%{F#3941d6}\uf293%{F-} $device"
	else
		if [ $connection = "↑" ]; then
			out="\uf293 "
		else
			out="%{F#FF0000}\uf293 %{F-}"
		fi
	fi
	echo "%{A3:bash $XDG_CONFIG_HOME/scripts/bluetooth_toggle.sh &:}%{A:bash $XDG_CONFIG_HOME/scripts/bluetooth_menu.sh &:}$out%{A}%{A3}"
}

wifi() {
	connection=$(nmcli -t -f type,device,state connection show | grep wireless | grep activated > /dev/null && echo "↑" || echo "↓")
	ssid=$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | cut -d: -f2)
	adress=$(ip -4 address show dev $WIFIDEVICE | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d/ -f1)
	signal=$(nmcli -f IN-USE,SIGNAL device wifi | grep \* | awk '{print $2}')
	if [ $connection = "↑" ]; then
		if [ $signal -le 33 ]; then
			out="%{F#FF0000}\uf1eb%{F-} $ssid $adress"
		elif [ $signal -gt 33 ] && [ $signal -lt 66 ]; then
			out="%{F#ffec00}\uf1eb%{F-} $ssid $adress"
		elif [ $signal -ge 66 ]; then
			out="%{F#06cf00}\uf1eb%{F-} $ssid $adress"
		else
			out="\uf1eb "
		fi
	else
		if [ $(nmcli networking | grep enabled) = "enabled" ] && [ $(nmcli radio wifi | grep enabled) = "enabled" ]; then
			out="\uf1eb "
		else
			out="%{F#FF0000}\uf1eb %{F-}"
		fi
	fi
	echo "%{A3:bash $XDG_CONFIG_HOME/scripts/wifi_menu_right_click.sh &:}%{A:bash $XDG_CONFIG_HOME/scripts/wifi_menu.sh &:}$out%{A}%{A3}"
}

ethernet() {
	connection=$(ip link show | grep -E 'state (UP|DOWN)' | grep $ETHERNETDEVICE | grep -v 'lo:' | grep -c 'state UP' | awk '{if($1 <= 0) print "↓"; else print "↑"}')
	adress=$(ip -4 address show dev $ETHERNETDEVICE | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
	if [ $connection = "↑" ]; then
		out="%{F#3941d6}\uf0ac%{F-} $adress"
	else
		if [ $(nmcli networking | grep enabled) = "enabled" ]; then
			out="\uf0ac "
		else
			out="%{F#FF0000}\uf0ac%{F-}"
		fi
	fi
	echo "%{A3:bash $XDG_CONFIG_HOME/scripts/wifi_menu_right_click.sh &:}$out%{A3}"
}

vpn() {
	connection=$(nmcli connection show --active | grep -q -E "vpn|wireguard" && echo "↑" || echo "↓")
	#name=$(nmcli connection show --active | grep vpn | awk '{print $1}')
	if [ $connection = "↑" ]; then
		out="%{F#3941d6}\uf542%{F-}"
	else
		if [ $(nmcli networking | grep enabled) = "enabled" ] ; then
			out="\uf542 "
		else
			out="%{F#FF0000}\uf542%{F-}"
		fi
	fi
	echo "%{A3:bash $XDG_CONFIG_HOME/scripts/wifi_menu_right_click.sh &:}$out%{A3}"
}

clock() {
    time=$(date "+%H:%M, %a, %b %d ")
    out="\uf073 $time"
    echo "%{A:$TERMINAL -e  sh ~/.config/scripts/calendar.sh &:}$out%{A}"
}

exit_ob(){
	out="\uf011"
	echo "%{A:bash $XDG_CONFIG_HOME/scripts/exit_menu.sh &:}$out%{A}"
}

keybindings() {
	out=" \uf11c"
	echo "%{A:bash $XDG_CONFIG_HOME/scripts/keybindings.sh &:}$out%{A}"
}

ext_devices() {
	device_list=""
	test -e /run/media/$(whoami) && devices=$(ls /run/media/$(whoami))
	for device in $devices; do
		device_path=$(df | grep $device | awk '{print $6}')
		device_usage=$(df | grep $device | awk '{print $5}')
		device_fs=$(df | grep $device | awk '{print $1}')
		device_list+="%{F#06cf00}%{A:$FILEMANAGER $device_path &:}%{A3:udiskie-umount $device_fs &:} \uf287%{F-} $device $device_usage %{A3}%{A}"
		out=$device_list
	done
	echo $out
}

cloud_sync() {
	if ps -e | grep -q sshfs; then
		out="%{A:$TERMINAL -e ssh $(cat $XDG_CONFIG_HOME/scripts/cloud_sync_conf | grep -w sshserver | awk '{print $2}') &:}%{F#1E90FF}\uf0c2%{F-}%{A}"
	else
		out="\uf0c2"
	fi
	echo $out
}

# STATUS BAR

while true; do
    BAR_S="%{l}$(keybindings)
    $(monitors)
    $(check_for_arch_updates)
    $(check_for_de_updates)
    $(ext_devices)
    %{r}
    $(cloud_sync)
	$(cpu)
	$(mem)
	$(swap)
	$(disk)
	$(battery)
    $(sound_volume)
    $(backlight)
    $(bluetooth)
    $(wifi)
    $(vpn)
    $(ethernet)
    $(my_uptime)
    $(clock)
    $(exit_ob)"
    echo -e $BAR_S
    sleep 1
done | lemonbar -a 100 -B $BGCOLOR -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash > logs/statusbar_log &
