#!/bin/bash

system_kernel() {
	echo "$(uname -r)"
}

check_for_arch_updates() {
	test -e ~/.nupdates && nupdates=$(cat ~/.nupdates)
	test -e ~/.nupdates && if [ "$nupdates" != 0 ]; then
		echo "%{A:$TERMINAL -e yay && bash $XDG_CONFIG_HOME/scripts/check_for_updates.sh &:}%{F#06cf00} \uf021%{F-} $nupdates%{A}"
	fi
}

check_for_de_updates() {
	test -e ~/.update_de && echo "%{A:bash $XDG_CONFIG_HOME/scripts/update_de.sh && bash $XDG_CONFIG_HOME/scripts/check_for_updates.sh &:}%{F#e013a4} \uf021%{F-}%{A}"
}

monitors() {
	primary_monitor=$(xrandr --listmonitors | tail -n +2 | grep '*' | awk '{print $NF}')
	if [ $(xrandr | grep $HDMI | awk '{print $2}') = 'connected' ]; then
		if [ $primary_monitor != $HDMI ]; then
			echo '%{A:bash $XDG_CONFIG_HOME/scripts/change_monitor.sh &:} \uf390%{A}'
		elif [ $primary_monitor = $HDMI ]; then
			echo '%{A:bash $XDG_CONFIG_HOME/scripts/change_monitor.sh &:} \uf109%{A}'
		fi
	fi
}

my_uptime() {
	hours=$(uptime | awk '{print $3}' | tr -d ',')
	echo " \uf64a $hours"
}

load() {
	values=$(uptime | awk -F 'load average: ' '{print $2}' | tr -d ',')
	value_15min=$(uptime | awk -F 'load average: ' '{print $2}' | awk -F ', ' '{print $3}')
	value_15min=${value_15min%.*}
	if [ $value_15min -lt 1 ]; then
        echo "%{F#06cf00}\ue473%{F-} $values"
	elif [ $value_15min -ge 1 ] && [ $value_15min -lt 2 ]; then
		echo "%{F#ffec00}\ue473%{F-} $values"
    else
        echo "%{F#FF0000}\ue473%{F-} $values"
    fi
}

sound_volume() {
	volume=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print $5}' | sed 's/%//')
	pactl list sinks | grep "Active Port" | grep -q headphones && port="\uf025" || if [ $volume -ge 50 ]; then
		port="\uf028"
	else
		port="\uf027"
	fi
	pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && port="%{F#FF0000}$port%{F-}"
	echo "$port $volume% "
}

backlight() {
	value=$(light -G | cut -c1-2)
	echo "\uf0eb $value%"
}

mem() {
	usage=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')
	usage=${usage%.*}
	if [ $usage -le 50 ]; then
        echo "%{F#06cf00}\uf1c0%{F-} $usage%"
	elif [ $usage -gt 50 ] && [ $usage -le 80 ]; then
		echo "%{F#ffec00}\uf1c0%{F-} $usage%"
    else
        echo "%{F#FF0000}\uf1c0%{F-} $usage%"
    fi
}

swap() {
    usage=$(free -m | awk 'NR==3{printf "%.1f%%", $3*100/$2 }')
    usage=${usage%.*}
    if [ "$usage" -le 50 ]; then
        echo "%{F#06cf00}\uf362%{F-} $usage%"
    elif [ "$usage" -gt 50 ] && [ "$usage" -le 80 ]; then
        echo "%{F#ffec00}\uf362%{F-} $usage%"
    else
        echo "%{F#FF0000}\uf362%{F-} $usage%"
    fi
}


cpu() {
    usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
	if [ $usage -le 50 ]; then
        echo "%{F#06cf00}\uf2db%{F-} $usage%"
	elif [ $usage -gt 50 ] && [ $usage -le 80 ]; then
		echo "%{F#ffec00}\uf2db%{F-} $usage%"
    else
        echo "%{F#FF0000}\uf2db%{F-} $usage%"
    fi
}

disk() {
	usage=$(df -x tmpfs -x devtmpfs -x devfs -h / | awk '{print $5}' | tail -n1)
	echo "\uf51f $usage%"
}

battery() {
    capacity=$(cat $BATDEVICE/capacity)
    status=$(cat $BATDEVICE/status | grep -q 'Charging\|Full' && echo "↑" || echo "↓")
    if [ $capacity -lt 10 ] &&  [ $status = '↓' ]; then
        echo "%{F#FF0000}\uf244%{F-} $capacity%"
	elif [ $status = '↑' ]; then
		echo "%{F#ffec00}\uf1e6%{F-} $capacity%"
    else
        echo "\uf242$capacity%"
    fi
}

bluetooth() {
	connection=$(bluetoothctl show | grep -q "Powered: yes" && echo "↑" || echo "↓")
	device=$(bluetoothctl info | grep -q "Connected: yes" && bluetoothctl info | grep -o 'Name:.*' | sed 's/Name: //')
	if [ $(bluetoothctl info | grep "Connected" | awk '{print $2}') ]; then
		echo "%{F#3941d6}\uf293%{F-} $device"
	else
		if [ $connection = "↑" ]; then
			echo "\uf293 "
		else
			echo "%{F#FF0000}\uf293 %{F-}"
		fi
	fi
}

wifi() {
	connection=$(nmcli -t -f type,device,state connection show | grep wireless | grep activated > /dev/null && echo "↑" || echo "↓")
	ssid=$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | cut -d: -f2)
	adress=$(ip -4 address show dev $WIFIDEVICE | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d/ -f1)
	signal=$(nmcli -f IN-USE,SIGNAL device wifi | grep \* | awk '{print $2}')
	if [ $connection = "↑" ]; then
		if [ $signal -le 33 ]; then
			echo "%{F#FF0000}\uf1eb%{F-} $ssid $adress"
		elif [ $signal -gt 33 ] && [ $signal -lt 66 ]; then
			echo "%{F#ffec00}\uf1eb%{F-} $ssid $adress"
		elif [ $signal -ge 66 ]; then
			echo "%{F#06cf00}\uf1eb%{F-} $ssid $adress"
		else
			echo "\uf1eb "
		fi
	else
		if [ $(nmcli networking | grep enabled) = "enabled" ] && [ $(nmcli radio wifi | grep enabled) = "enabled" ]; then
			echo "\uf1eb "
		else
			echo "%{F#FF0000}\uf1eb %{F-}"
		fi
	fi
}

ethernet() {
	connection=$(ip link show | grep -E 'state (UP|DOWN)' | grep $ETHERNETDEVICE | grep -v 'lo:' | grep -c 'state UP' | awk '{if($1 <= 0) print "↓"; else print "↑"}')
	adress=$(ip -4 address show dev $ETHERNETDEVICE | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
	if [ $connection = "↑" ]; then
		echo "%{F#3941d6}\uf0ac%{F-} $adress"
	else
		if [ $(nmcli networking | grep enabled) = "enabled" ]; then
			echo "\uf0ac "
		else
			echo "%{F#FF0000}\uf0ac%{F-}"
		fi
	fi
}

vpn() {
	connection=$(nmcli connection show --active | grep -q -E "vpn|wireguard" && echo "↑" || echo "↓")
	#name=$(nmcli connection show --active | grep vpn | awk '{print $1}')
	if [ $connection = "↑" ]; then
		echo "%{F#3941d6}\uf542%{F-}"
	else
		if [ $(nmcli networking | grep enabled) = "enabled" ] ; then
			echo "\uf542 "
		else
			echo "%{F#FF0000}\uf542%{F-}"
		fi
	fi
}

clock() {
    time=$(date "+%H:%M, %a, %b %d ")
    echo "\uf073 $time"
}

exit_ob(){
	echo "%{A:bash $XDG_CONFIG_HOME/scripts/exit_menu.sh &:}\uf011%{A}"
}

launchers_status_bar() {
	echo "%{A:bash $XDG_CONFIG_HOME/scripts/keybindings.sh &:} \uf11c%{A}"
}

ext_devices() {
	device_list=""
	test -e /run/media/$(whoami) && devices=$(ls /run/media/$(whoami))
	for device in $devices; do
		device_path=$(df | grep $device | awk '{print $6}')
		device_usage=$(df | grep $device | awk '{print $5}')
		device_fs=$(df | grep $device | awk '{print $1}')
		device_list+="%{F#06cf00}%{A:$FILEMANAGER $device_path &:}%{A3:udiskie-umount $device_fs &:} \uf287%{F-} $device $device_usage %{A3}%{A}"
	done
	echo $device_list
}

# STATUS BAR

while true; do
    BAR_S="%{l}$(launchers_status_bar)
    $(monitors)
    $(check_for_arch_updates)
    $(check_for_de_updates)
    $(ext_devices)
    %{r}
    %{A:$TERMINAL -e htop &:}
	$(cpu)
	$(load)
	$(mem)
	$(swap)
	$(disk)%{A}
	$(battery)
    %{A3:pactl set-sink-mute @DEFAULT_SINK@ toggle &:}%{A:$CTRLSOUND &:}$(sound_volume)%{A}%{A3}
    $(backlight)
    %{A3:bash $XDG_CONFIG_HOME/scripts/bluetooth_toggle.sh &:}%{A:bash $XDG_CONFIG_HOME/scripts/bluetooth_menu.sh &:}$(bluetooth)%{A}%{A3}
    %{A3:bash $XDG_CONFIG_HOME/scripts/wifi_menu_right_click.sh &:}%{A:bash $XDG_CONFIG_HOME/scripts/wifi_menu.sh &:}$(wifi)%{A}
    $(vpn)
    $(ethernet)
    %{A3}
    $(my_uptime)
    %{A:$TERMINAL -e  sh ~/.config/scripts/calendar.sh &:}$(clock)%{A}
    $(exit_ob)"
    echo -e $BAR_S
    sleep 1
done | lemonbar -a 100 -B $(cat $COLORS | grep -w BGCOLOR | awk '{print $2}') -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash &
