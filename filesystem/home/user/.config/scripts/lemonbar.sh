#!/bin/bash

# CHECK FOR SYSTEM UPDATES

echo 0 > .nupdates

while true; do
    ping -q -c 1 -W 1 ping.eu > /dev/null && yay -Qu | wc -l > ~/.nupdates
    sleep 600
done &

# STATUS BAR FUNCS

system_kernel() {
	echo "$(uname -r)"
}

update_system() {
	test -e ~/.nupdates && nupdates=$(cat ~/.nupdates)
	test -e ~/.nupdates && if [ "$nupdates" != 0 ]; then
		echo "%{A:$TERMINAL -e yay &:}%{F#06cf00} \uf021%{F-} $nupdates%{A}"
	else
		echo " "
	fi
}

my_uptime() {
	hours=$(uptime | awk '{print $3}' | tr -d ',')
	echo " \uf64a $hours"
}

load() {
	values=$(uptime | awk -F 'load average: ' '{print $2}' | tr -d ',')
	echo "\ue473 $values"
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
	echo "\uf1c0 $usage" 
}

cpu() {
	usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)"%"}')
	echo "\uf2db ~ $usage"
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
	if [ $connection = "↑" ]; then
		echo "%{F#3941d6}\uf293%{F-} $device"
	else
		echo "\uf293 $connection"
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
			echo "\uf1eb $connection"
		fi
	else
		echo "\uf1eb $connection"
	fi
}

ethernet() {
	connection=$(ip link show | grep -E 'state (UP|DOWN)' | grep $ETHERNETDEVICE | grep -v 'lo:' | grep -c 'state UP' | awk '{if($1 <= 0) print "↓"; else print "↑"}')
	adress=$(ip -4 address show dev $ETHERNETDEVICE | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
	if [ $connection = "↑" ]; then
		echo "%{F#3941d6}\uf0ac%{F-} $adress"
	else
		echo "\uf0ac$connection"
	fi
}

vpn() {
	connection=$(nmcli connection show --active | grep -q vpn && echo "↑" || echo "↓")
	#name=$(nmcli connection show --active | grep vpn | awk '{print $1}')
	if [ $connection = "↑" ]; then
		echo "%{F#3941d6}\uf542%{F-}"
	else
		echo "\uf542$connection"
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
    $(update_system)
    $(ext_devices)
    %{r}
    %{A:$TERMINAL -e htop &:}
	$(cpu) 
	$(load) 
	$(mem) 
	$(disk)%{A} 
	$(battery) 
    %{A:pavucontrol &:}$(sound_volume)%{A} 
    $(backlight) 
    %{A3:bash $XDG_CONFIG_HOME/scripts/bluetooth_toggle.sh &:}%{A:blueman-manager &:}$(bluetooth)%{A}%{A3}
    %{A3:bash $XDG_CONFIG_HOME/scripts/wifi_menu_right_click.sh &:}%{A:bash $XDG_CONFIG_HOME/scripts/wifi_menu.sh &:}$(wifi)%{A} 
    $(vpn) 
    $(ethernet) 
    %{A3}
    $(my_uptime)
    %{A:bash $XDG_CONFIG_HOME/scripts/wifi-menu.sh &:}$(clock)%{A} 
    $(exit_ob)" 
    echo -e $BAR_S
    sleep 1
done | lemonbar -a 100 -B "#383c4a" -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash &

# TASKBAR FUNCS

button_state() {
    active_win=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}' | awk '{print strtonum("0x" substr($0, 3))}')
    DEC_ID1=$(printf "%d" $active_win)
    DEC_ID2=$(printf "%d" $1)
    if [ $DEC_ID1 == $DEC_ID2 ]; then
        echo "%{B#5294e2} \x20 $2 \x20 %{B-}"
    else
        echo " \x20 $2 \x20 "
    fi
}

launchers_taskbar() {
	echo "%{A:$TERMINAL &:} \uf120%{A} 
		%{A: $FILEMANAGER &:} \uf07c%{A}" 
}

# TASKBAR

xev -root | grep -E --line-buffered "_NET_ACTIVE_WINDOW|CreateNotify|DestroyNotify|_NET_CURRENT_DESKTOP" | while read line; do
	deskid=$(wmctrl -d | grep '*' | cut -d ' ' -f 1)
	desktops=''
	for dID in $(wmctrl -d | awk '{print $1}'); do
		if [ $deskid == $dID ]; then
			desktops+="%{B#5294e2}\x20$dID\x20%{B-}"
		else
			desktops+="%{A: wmctrl -s $dID &:}\x20$dID\x20%{A}"
		fi
	done
    IDS=$(wmctrl -l | awk '$2 == "'"$deskid"'"' | awk '{print $1}')
    BAR_INPUT="%{l}$desktops %{c}"
    for ID in $IDS; do
        NAME=$(wmctrl -l | grep $ID | awk '{$1=""; $2=""; $3=""; sub(/^ */, ""); title=$0; if(length(title)>10) title=substr(title, 1, 10) " ..."; print title}')
        BAR_INPUT+="%{A: wmctrl -i -a $ID &:}%{A3: wmctrl -i -c $ID &:}$(button_state $ID "$NAME")%{A}%{A3}"
    done
    echo -e $BAR_INPUT
done | lemonbar -a 100 -b -B "#383c4a" -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash &
