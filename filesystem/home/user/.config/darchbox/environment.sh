#!/bin/bash

# PATHS

export XDG_CONFIG_HOME=$HOME/.config

# DEVICES

export BATDEVICE=$(echo /sys/class/power_supply/$(ls /sys/class/power_supply/ | grep BAT))
export WIFIDEVICE=$(nmcli device status | awk '$2=="wifi"{print $1}')
export ETHERNETDEVICE=$(nmcli device status | awk '$2=="ethernet"{print $1}')
export SCREENW=$(xrandr | awk '/current/ {print $8}')
export SCREENH=$(xrandr | awk '/current/ {print $10}' | tr -d ',')

# FILES

export CONFIG_FILES_LIST="$XDG_CONFIG_HOME/openbox/* $XDG_CONFIG_HOME/darchbox/* $HOME/.config/gtk-3.0/settings.ini $HOME/.gtkrc-2.0 $HOME/.bashrc $HOME/.Xresources $HOME/.xinitrc"

# APPLICATIONS

flag=false
ICONS=()
while read -r app; do
	if [[ "$app" == "# applications" ]]; then
		flag=true
		continue
	fi
	if [[ "$app" == "##" ]]; then
		flag=false
	fi
	if $flag; then
		
		app_name=$(echo "$app" | awk '{print $1}')
		eval "$app_name() {
		  app_cmd=\$(cat \$XDG_CONFIG_HOME/darchbox/configs | grep $app_name | awk '{print substr(\$0, index(\$0,\$2))}')
		  \$app_cmd \"\$@\";
		}"
		export -f $app_name

	fi
done < $XDG_CONFIG_HOME/darchbox/configs

		
# FUNCTIONS

ef_terminal() {
	if ! tmux info &> /dev/null; then
		byobu new-session -d -s base_session
	fi
	if [ -n "$1" ]; then
        byobu new-window -t base_session "$1"
    fi
    if wmctrl -l | grep -q "byobu"; then
		term_window=$( wmctrl -l | grep "byobu" | awk '{print $1}')
		wmctrl -i -r $term_window -t $(wmctrl -d | grep '*' | cut -d ' ' -f 1)
        wmctrl -i -a $term_window
    else
		xterm byobu
    fi
}

export -f ef_terminal

ef_one_instance() {
	if pgrep -x "$1" > /dev/null; then
        window=$( wmctrl -lx | grep "$1" | awk '{print $1}')
		wmctrl -i -r $window -t $(wmctrl -d | grep '*' | cut -d ' ' -f 1)
        wmctrl -i -a $window
    else
        "$1" &
    fi
}

export -f ef_one_instance

ef_arch_docs() {
	
	search_term=$(curl -sS "https://wiki.archlinux.org/title/Table_of_contents" | grep -o '<a href="/title/Category:[^>]*>[^<]*</a>' | sed 's/<[^>]*>//g' | dmenu -p 'Search Arch docs:')

	if [ -n "$search_term" ]; then
		surf "https://wiki.archlinux.org/index.php?search=${search_term}"
	fi

}

export -f ef_arch_docs

ef_bluetooth_menu() {

	devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
	selection=$(echo "$devices" | dmenu -p 'Connect to Bluetooth device:')

	if [ -n "$selection" ]; then
		mac=$(echo "$selection" | cut -f1 -d' ')
		echo -e "connect $mac\nquit" | bluetoothctl
	fi

}

export -f ef_bluetooth_menu

ef_bluetooth_toggle() {

	bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on

}

export -f ef_bluetooth_toggle

ef_calendar() {
	
	date=$(dialog --stdout \
	  --title "Calendar" \
	  --ok-label "Copy" \
	  --calendar "Select date" 0 0 )

	if [ -n "$date" ]; then
	  echo -n "$date" | xclip -selection clipboard
	  clear
	fi

}

export -f ef_calendar

ef_check_for_updates() {
	
	# check whether internet connection is on

	while ! ping -q -c 1 -W 1 ping.eu > /dev/null ; do
		sleep 5
	done

	# check for Arch linux updates and save the number of updates to file

	echo 0 > ~/.nupdates
	yay -Qu | wc -l > ~/.nupdates

}

export -f ef_check_for_updates

ef_update_arch() {
	
	ef_terminal yay
	ef_check_for_updates 
	
}

export -f ef_update_arch

ef_exit_menu() {
	
	option0="Lock"
	option1="Leave X"
	option2="Reboot"
	option3="Shutdown"

	options="$option0\n$option1\n$option2\n$option3"

	chosen="$(echo -e "$options" | dmenu )"
	case $chosen in
	$option0)
		slock;;
	$option1)
		openbox --exit;;
	$option2)
		reboot;;
	$option3)
		shutdown now;;
esac

}

export -f ef_exit_menu

ef_install_packages() {
	
	flag=false
	
	PKGS=()
	while read -r line; do
		if [[ "$line" == "# optional install packages" ]]; then
			flag=true
			continue
		fi
		if [[ "$line" == "##" ]]; then
			flag=false
		fi
		if $flag; then
			PKGS+=("$line" "" off)
		fi
	done < $XDG_CONFIG_HOME/darchbox/configs

	SELECTION_INSTALL=$(dialog --title "Install packages" --separate-output --checklist "Select packages:" 20 60 14 "${PKGS[@]}" 3>&1 1>&2 2>&3)
	clear
	for PKG in ${SELECTION_INSTALL[@]}; do
	yay -S --needed --noconfirm $PKG
	done

}

export -f ef_install_packages

ef_keybindings() {

	CONFIG_FILE=$XDG_CONFIG_HOME/openbox/rc.xml
	key_coment=$(awk -F'[<>"]+' '/<!--kb/ {comment=substr($2, 6); gsub(/-+$/, "", comment)} /<keybind/ {if (comment) {key=$4}} /<command>/ {command=$3} /<\/command>/ {gsub(/^\s+|\s+$/, "", command); if (comment) {print "(" key ") " comment; comment=""}}' "$CONFIG_FILE")
	key_coment_command=$(awk -F'[<>"]+' '/<!--kb/ {comment=substr($2, 6); gsub(/-+$/, "", comment)} /<keybind/ {if (comment) {key=$4}} /<command>/ {command=$3} /<\/command>/ {gsub(/^\s+|\s+$/, "", command); if (comment) {print "(" key ") " comment " : " command; comment=""}}' "$CONFIG_FILE")
	selected_key=$(echo "$key_coment" | dmenu -l 40)
	if [ -n "$selected_key" ]; then
		command=$(echo "$key_coment_command" | grep "$selected_key" | awk -F':' '{print $2}')
		eval "$command"
	fi

}

export -f ef_keybindings

ef_launch_apps() {
	
	dmenu_run -p 'Launch application:'

}

export -f ef_launch_apps

ef_refresh() {
	
	openbox --reconfigure
	killall -SIGUSR2 lemonbar
	sleep 0.1
	ef_statusbar_taskbar
	
}

export -f ef_refresh

ef_search_home() {
	
	options="$(find $HOME -type f -printf '%f\n')"
	chosen="$(echo -e "$options" | dmenu -p 'Search ~:')"
	xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"

}

export -f ef_search_home

ef_set_wallpaper() {
	
	list_files=$(ls ~/wallpapers)
	random_file=$(echo $list_files | tr " " "\n" | shuf -n 1)
	feh --bg-fill ~/wallpapers/$random_file
	
}

export -f ef_set_wallpaper

ef_wifi_menu() {
	
	selected=$(nmcli -t -f ssid dev wifi | grep -E -v '^$' | dmenu -p 'Connect to Wi-FI:')

	if [[ -n "$selected" ]]; then
		if nmcli -s -g 802-11-wireless-security.psk connection show '$selected' 2>&1 | grep -q "no such connection profile"; then
			$TERMINAL -e nmcli --ask device wifi connect "$selected"
		else
			nmcli device wifi connect "$selected"
		fi
	fi
	
}

export -f ef_wifi_menu

ef_network_menu() {
	
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

	echo -e "Connect/Disconnect Wi-Fi\nEnable/Disable Wi-Fi\nEnable/Disable Networking" | dmenu -p 'Network Options:' | xargs -I{} sh -c 'if [ "{}" = "Connect/Disconnect Wi-Fi" ]; then connect_disconnect_wifi; elif [ "{}" = "Enable/Disable Wi-Fi" ]; then toggle_wifi; elif [ "{}" = "Enable/Disable Networking" ]; then toggle_networking; fi'

}

export -f ef_network_menu

ef_cloud_sync() {
	
	sshserver=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sshserver | awk '{print $2}')
	remote_mount_point=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w remote_mount_point | awk '{print $2}')
	local_mount_point=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w local_mount_point | awk '{print $2}')
	sync_source_dir=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sync_source_dir | awk '{print $2}')
	sync_target_dir=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sync_target_dir | awk '{print $2}')

	sync() {
		if ps -e | grep -q sshfs; then
			rsync -avz --delete $sync_source_dir $sync_target_dir
			notify-send "Cloud sync event $( echo $out | awk '{print $2 , $3}')"
		fi
	}

	check_connection() {
		while ! ping -q -c 1 -W 1 ping.eu > /dev/null ; do
			sleep 5
		done
	}

	monitor_and_sync() {
		while out=$(inotifywait -r -e modify,create,delete,move $sync_source_dir); do
			sync
		done
	}

	check_connection

	sshfs -o reconnect $sshserver:$remote_mount_point $local_mount_point

	sync

	# the loop bellow re-runs inotify whenever it stops runing, for instance when a folder is deleted (inotify stops because it is watching directories recursively

	while true; do
		monitor_and_sync
	done

}

export -f ef_cloud_sync

ef_ssh_cloud() {
	
	ef_terminal "ssh $(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sshserver | awk '{print $2}')"
	
}

export -f ef_ssh_cloud

# STATUS AND TASK BAR

ef_statusbar_taskbar() {

	COLORS=$XDG_CONFIG_HOME/darchbox/configs
	COLOR='#005577'
	BGCOLOR='#272930'
	BGCOLOR2='#222222'
	FGCOLOR='#EBF2FF'

	# taskbar funcs
	
	flag=false
	ICONS=()
	while read -r line; do
		if [[ "$line" == "# taskbar icons" ]]; then
			flag=true
			continue
		fi
		if [[ "$line" == "##" ]]; then
			flag=false
		fi
		if $flag; then
			ICONS+=("$line")
		fi
	done < $XDG_CONFIG_HOME/darchbox/configs
	
	chosen_icon() {
		window=$(wmctrl -lx | grep $1)
		out="%{F#FFFFFF)}\uf15b%{F-}"
		for i in "${ICONS[@]}"; do
			[[ $window == *$(echo $i | awk '{print $1}')* ]] && out="%{F$(echo $i | awk '{print $3}')}$(echo $i | awk '{print $2}')%{F-}" && break
		done
		echo $out
	}

	button_state() {
		active_win=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}' | awk '{print strtonum("0x" substr($0, 3))}')
		DEC_ID1=$(printf "%d" $active_win)
		DEC_ID2=$(printf "%d" $1)
		if [ $DEC_ID1 == $DEC_ID2 ]; then
			echo "%{B$COLOR} $2 %{B-}"
		else
			echo " $2 "
		fi
	}

	buttons() {
		deskid=$(wmctrl -d | grep '*' | cut -d ' ' -f 1)
		desktop="%{A: wmctrl -s $(((deskid + 1) % 4))  &:}%{A3: wmctrl -s $(((deskid - 1) % 4))  &:}%{B$COLOR}\x20$((deskid + 1))\x20%{B-}%{A}%{A3}"
		IDS=$(wmctrl -l | awk '$2 == "'"$deskid"'"' | awk '{print $1}')
		BAR_INPUT="%{l}$desktop "
		for ID in $IDS; do
			ICON=$(chosen_icon $ID)
			BAR_INPUT+="%{B$BGCOLOR2}%{A: wmctrl -i -a $ID &:}%{A3: wmctrl -i -c $ID &:}$(button_state $ID "$ICON")%{A}%{A3}%{B-}"
		done
		echo $BAR_INPUT
	}

	# statusbar funcs

	system_kernel() {
		echo "$(uname -r)"
	}

	update_arch() {
		test -e ~/.nupdates && nupdates=$(cat ~/.nupdates)
		test -e ~/.nupdates && if [ "$nupdates" != 0 ]; then
			out="%{F#06cf00} \uf021%{F-} $nupdates"
		fi
		
		echo "%{A:ef_update_arch &:}$out%{A}"
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
		pactl list sinks | grep "Active Port" | grep -q Headphones && port="\uf025" || if [ $volume -ge 50 ]; then
			port="\uf028"
		else
			port="\uf027"
		fi
		pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && port="%{F#FF0000}$port%{F-}"
		out="$port $volume%"
		echo "%{A3:pactl set-sink-mute @DEFAULT_SINK@ toggle &:}%{A:CTRLSOUND &:}$out %{A}%{A3}"
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
		echo "%{A:TASKMAN &:}$out %{A}"
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
		echo "%{A:TASKMAN &:}$out %{A}"
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
		echo "%{A:TASKMAN &:}$out %{A}"
	}

	disk() {
		usage=$(df -x tmpfs -x devtmpfs -x devfs -h / | awk '{print $5}' | tail -n1)
		out="\uf51f $usage%"
		echo "%{A:TASKMAN & :}$out %{A}"
	}

	battery() {
		capacity=$(cat $BATDEVICE/capacity)
		status=$(cat $BATDEVICE/status)
		if [ $capacity -lt 10 ] &&  [ $status = 'Discharging' ]; then
			out="%{F#FF0000}\uf244%{F-} $capacity%"
		elif [ $capacity -lt 20 ] &&  [ $status = 'Discharging' ]; then
			out="%{F#FF0000}\uf243%{F-} $capacity%"
		elif [ $capacity -lt 30 ] &&  [ $status = 'Discharging' ]; then
			out="%{F#FFA500}\uf242%{F-} $capacity%"
		elif [ $capacity -gt 29 ] &&  [ $status = 'Discharging' ]; then
			out="\uf242 $capacity%"
		elif [ $capacity -gt 50 ] &&  [ $status = 'Discharging' ]; then
			out="\uf241 $capacity%"
		elif [ $status = 'Charging' ]; then
			out="%{F#ffec00}\uf0e7%{F-} $capacity%"
		elif [ $status = 'Full' ]; then
			out="%{F#ffec00}\uf1e6%{F-} $capacity%"
		elif [ $status = 'Not Charging' ]; then
			out="%{F#ffec00}\uf1e6%{F-} $capacity%"
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
		echo "%{A3:ef_bluetooth_toggle:}%{A:ef_bluetooth_menu:}$out%{A}%{A3}"
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
		echo "%{A3:ef_network_menu:}%{A:ef_wifi_menu:}$out%{A}%{A3}"
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
		echo "%{A3:ef_network_menu:}$out%{A3}"
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
		echo "%{A3:ef_network_menu:}$out%{A3}"
	}

	clock() {
		time=$(date "+%H:%M, %a, %b %d ")
		out="\uf073 $time"
		echo "%{A:CALENDAR &:}$out%{A}"
	}

	exit_ob(){
		out="\uf011"
		echo "%{A:ef_exit_menu:}$out%{A}"
	}

	keybindings() {
		out=" \uf11c"
		echo "%{A:ef_keybindings:}$out%{A}"
	}

	ext_devices() {
		device_list=""
		test -e /run/media/$(whoami) && devices=$(ls /run/media/$(whoami))
		for device in $devices; do
			device_path=$(df | grep $device | awk '{print $6}')
			device_usage=$(df | grep $device | awk '{print $5}')
			device_fs=$(df | grep $device | awk '{print $1}')
			device_list+="%{F#06cf00}%{A:FILEMANAGER $device_path &:}%{A3:udiskie-umount $device_fs &:} \uf287%{F-} $device $device_usage %{A3}%{A}"
			out=$device_list
		done
		echo $out
	}

	cloud_sync() {
		if ps -e | grep -q sshfs; then
			servername=$(cat $XDG_CONFIG_HOME/darchbox/cloud_sync_conf | grep -w sshserver | awk '{print $2}')
			out="%{A:ef_ssh_cloud &:}%{F#1E90FF}\uf0c2%{F-}%{A}"
		else
			out="\uf0c2"
		fi
		echo $out
	}

	# taskbar
	SEP=$(printf "%.0f" "$((SCREENW / 5))")

	xev -root | grep -E --line-buffered "_NET_ACTIVE_WINDOW|CreateNotify|DestroyNotify|_NET_CURRENT_DESKTOP" | while read line; do
		BAR_INPUT="$(buttons)"
		echo -e $BAR_INPUT
	done | lemonbar -a 100 -g ${SEP}x -B $BGCOLOR2 -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash &


	# status bar

	while true; do
		BAR_S="
		%{r}
		$(ext_devices)
		$(update_arch)
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
		$(clock)"
		echo -e $BAR_S
		sleep 0.5
	done | lemonbar -a 100 -g +${SEP}x -B $BGCOLOR -F $FGCOLOR -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash &
		
}

export -f ef_statusbar_taskbar
