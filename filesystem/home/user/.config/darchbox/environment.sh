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

# MENUS

rofi_drun(){
	rofi -show drun -theme $XDG_CONFIG_HOME/rofi/hmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary
}

export -f rofi_drun

rofi_hmenu(){
	rofi -dmenu -theme $XDG_CONFIG_HOME/rofi/hmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary
}

export -f rofi_hmenu

rofi_vmenu(){
	rofi -dmenu -theme $XDG_CONFIG_HOME/rofi/vmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary -no-fixed-num-lines
}

export -f rofi_vmenu

# APPLICATIONS

flag=false
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
	
	search_term=$(curl -sS "https://wiki.archlinux.org/title/Table_of_contents" | grep -o '<a href="/title/Category:[^>]*>[^<]*</a>' | sed 's/<[^>]*>//g' | rofi_hmenu)

	if [ -n "$search_term" ]; then
		surf "https://wiki.archlinux.org/index.php?search=${search_term}"
	fi

}

export -f ef_arch_docs

ef_bluetooth_menu() {

	devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
	selection=$(echo "$devices" | rofi_hmenu)

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

	chosen="$(echo -e "$options" | rofi_hmenu )"
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
	selected_key=$(echo "$key_coment" | rofi_vmenu)
	if [ -n "$selected_key" ]; then
		sleep 0.1
		command=$(echo "$key_coment_command" | grep "$selected_key" | awk -F':' '{print $2}')
		eval "$command"
	fi

}

export -f ef_keybindings

ef_launch_apps() {
	
	rofi_drun

}

export -f ef_launch_apps

ef_refresh() {
	
	openbox --reconfigure
	killall -SIGUSR2 lemonbar
	sleep 0.1
	ef_statusbar
	
}

export -f ef_refresh

ef_search_home() {
	
	options="$(find $HOME -type f -printf '%f\n')"
	chosen="$(echo -e "$options" | rofi_hmenu)"
	xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"

}

export -f ef_search_home

ef_set_wallpaper() {
	
	list_files=$(ls ~/wallpapers)
	random_file=$(echo $list_files | tr " " "\n" | shuf -n 1)
	feh --bg-fill ~/wallpapers/$random_file
	
}

export -f ef_set_wallpaper

ef_network_menu() {
    
    wifi_menu() {
	
		selected=$(nmcli -t -f ssid dev wifi | grep -E -v '^$' | rofi_hmenu)

		if [[ -n "$selected" ]]; then
			if nmcli -s -g 802-11-wireless-security.psk connection show "$selected" 2>&1 | grep -q "no such connection profile"; then
				password=$(echo "" | rofi_hmenu)
				nmcli device wifi connect "$selected" password "$password"
			else
				nmcli device wifi connect "$selected"
			fi
		fi
	
	}
    
    connect_disconnect_wifi() {
        nmcli device | grep wifi | awk '{print $3}' | grep -w connected && nmcli device disconnect $WIFIDEVICE || nmcli device connect $WIFIDEVICE
    }

    toggle_wifi() {
        nmcli radio wifi | grep enabled && nmcli radio wifi off || nmcli radio wifi on
    }

    toggle_networking() {
        nmcli networking | grep enabled && nmcli networking off || nmcli networking on
    }

    option=$(echo -e "Wifi connections\nConnect/Disconnect Wi-Fi\nEnable/Disable Wi-Fi\nEnable/Disable Networking" | rofi_hmenu)

	if [[ -n "$option" ]]; then
		case "$option" in
			"Wifi connections")
				wifi_menu
				;;
			"Connect/Disconnect Wi-Fi")
				connect_disconnect_wifi
				;;
			"Enable/Disable Wi-Fi")
				toggle_wifi
				;;
			"Enable/Disable Networking")
				toggle_networking
				;;
		esac
	fi

}


export -f ef_network_menu

function ef_eval_string_after_network() {
	
    target="$1"
    interval="$2"
    
    while ! ping -q -c 1 -W 1 "$target" > /dev/null; do
        sleep "$interval"
    done
    
    shift 2
    eval "$@"
    
}

export -f ef_eval_string_after_network

ef_cloud_connect() {
	
	sshserver=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sshserver | awk '{print $2}')
	remote_mount_point=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w remote_mount_point | awk '{print $2}')
	local_mount_point=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w local_mount_point | awk '{print $2}')

	sshfs -o reconnect $sshserver:$remote_mount_point $local_mount_point

}

export -f ef_cloud_connect

ef_ssh_cloud() {
	
	ef_terminal "ssh $(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sshserver | awk '{print $2}')"
	
}

export -f ef_ssh_cloud

# STATUS AND TASK BAR

ef_statusbar() {

	COLOR='#005577'
	BGCOLOR='#272930'
	BGCOLOR2='#222222'
	FGCOLOR='#EBF2FF'

	blue="%{F#3941d6}"
	light_blue="%{F#1E8FFE}"
	red="%{F#FF0000}"
	yellow="%{F#ffec00}"
	green="%{F#06cf00}"
	orange="%{F#FFA500}"
	reset_color="%{F-}"
	
	sbar_menu() {
		echo "%{A:ef_keybindings :}\uf0c9 %{A}"
	}

	sbar_update_arch() {
		update_icon="\uf021"
		test -e ~/.nupdates && nupdates=$(cat ~/.nupdates)
		test -e ~/.nupdates && if [ "$nupdates" != 0 ]; then
			out="$green$update_icon$reset_color $nupdates"
		fi
		
		echo "%{A:ef_update_arch &:}$out %{A}"
	}

	sbar_my_uptime() {
		hours=$(uptime | awk '{print $3}' | tr -d ',')
		out=" \uf64a $hours"
		echo $out
	}

	sbar_sound_volume() {
		volume=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print $5}' | sed 's/%//')
		pactl list sinks | grep "Active Port" | grep -q Headphones && port="\uf025" || if [ $volume -ge 50 ]; then
			port="\uf028"
		elif [ $volume -le 0 ]; then
			port="\uf026"
		else
			port="\uf027"
		fi
		pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && port="$red$port$reset_color"
		out="$port $volume%"
		echo "%{A3:pactl set-sink-mute @DEFAULT_SINK@ toggle &:}%{A:CTRLSOUND &:}$out %{A}%{A3}"
	}

	sbar_backlight() {
		value=$(light -G | sed 's/\..*//')
		out="\uf0eb $value%"
		echo $out
	}

	sbar_mem() {
		memory_icon="\uf1c0"
		usage=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')
		usage=${usage%.*}
		if [ $usage -le 50 ]; then
			out="$green$memory_icon$reset_color $usage%"
		elif [ $usage -gt 50 ] && [ $usage -le 80 ]; then
			out="$yellow$memory_icon$reset_color $usage%"
		else
			out="$red$memory_icon$reset_color $usage%"
		fi
		echo "%{A:TASKMAN &:}$out %{A}"
	}

	sbar_cpu() {
		cpu_icon="\uf2db"
		usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
		if [ $usage -le 50 ]; then
			out="$green$cpu_icon$reset_color $usage%"
		elif [ $usage -gt 50 ] && [ $usage -le 80 ]; then
			out="$yellow$cpu_icon$reset_color $usage%"
		else
			out="$red$cpu_icon$reset_color $usage%"
		fi
		echo "%{A:TASKMAN &:}$out %{A}"
	}

	sbar_battery() {
		battery_empty_icon="\uf244"
		battery_quarter_icon="\uf243"
		battery_half_icon="\uf242"
		battery_3quarters_icon="\uf241"
		battery_full_icon="\uf240"
		charging_icon="\uf0e7"
		plug_icon="\uf1e6"
		
		capacity=$(cat $BATDEVICE/capacity)
		status=$(cat $BATDEVICE/status)
		if [ $capacity -lt 10 ] &&  [ $status = 'Discharging' ]; then
			out="$red$battery_empty_icon$reset_color $capacity%"
		elif [ $capacity -lt 25 ] &&  [ $status = 'Discharging' ]; then
			out="$red$battery_quarter_icon$reset_color $capacity%"
		elif [ $capacity -lt 50 ] &&  [ $status = 'Discharging' ]; then
			out="$orange$battery_half_icon$reset_color $capacity%"
		elif [ $capacity -lt 75 ] &&  [ $status = 'Discharging' ]; then
			out="$battery_3quarters_icon $capacity%"
		elif [ $capacity -lt 100 ] &&  [ $status = 'Discharging' ]; then
			out="$battery_full_icon $capacity%"
		elif [ $status = 'Charging' ]; then
			out="$yellow$charging_icon$reset_color $capacity%"
		elif [ $status = 'Full' ]; then
			out="$yellow$plug_icon$reset_color $capacity%"
		elif [ $status = 'Not Charging' ]; then
			out="$yellow$plug_icon$reset_color $capacity%"
		fi
		echo $out
	}

	sbar_bluetooth() {
		bluetooth_icon="\uf293"
		connection=$(bluetoothctl show | grep -q "Powered: yes" && echo "up" || echo "down")
		device=$(bluetoothctl info | grep -q "Connected: yes" && bluetoothctl info | grep -o 'Name:.*' | sed 's/Name: //')
		if [ "$(bluetoothctl info | grep "Connected" | awk '{print $2}')" ]; then
			out="$blue$bluetooth_icon$reset_color $device"
		else
			if [ "$connection" = "up" ]; then
				out="$bluetooth_icon"
			else
				out="$red$bluetooth_icon$reset_color"
			fi
		fi
		echo "%{A3:ef_bluetooth_toggle:}%{A:ef_bluetooth_menu:}$out%{A}%{A3}"
	}

	sbar_wifi() {
		wifi_icon="\uf1eb"
		connection=$(nmcli -t -f type,device,state connection show | grep wireless | grep activated > /dev/null && echo "up" || echo "down")
		ssid=$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | cut -d: -f2)
		adress=$(ip -4 address show dev $WIFIDEVICE | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d/ -f1)
		signal=$(nmcli -f IN-USE,SIGNAL device wifi | grep \* | awk '{print $2}')
		if [ "$connection" = "up" ]; then
			if [ $signal -le 33 ]; then
				out="$red$wifi_icon$reset_color $ssid $adress"
			elif [ $signal -gt 33 ] && [ $signal -lt 66 ]; then
				out="$yellow$wifi_icon$reset_color $ssid $adress"
			elif [ $signal -ge 66 ]; then
				out="$green$wifi_icon$reset_color $ssid $adress"
			else
				out="$wifi_icon"
			fi
		else
			if [ "$(nmcli networking | grep enabled)" = "enabled" ] && [ "$(nmcli radio wifi | grep enabled)" = "enabled" ]; then
				out="$wifi_icon"
			else
				out="$red$wifi_icon$reset_color"
			fi
		fi
		echo "%{A:ef_network_menu:}$out%{A}"
	}

	sbar_vpn() {
		vpn_icon="\uf542"
		connection=$(nmcli connection show --active | grep -q -E "vpn|wireguard" && echo "up" || echo "down")
		if [ "$connection" = "up" ]; then
			out="$blue$vpn_icon$reset_color"
		else
			if [ "$(nmcli networking | grep enabled)" = "enabled" ] ; then
				out="$vpn_icon"
			else
				out="$red$vpn_icon$reset_color"
			fi
		fi
		echo "%{A:ef_network_menu:}$out%{A}"
	}

	sbar_clock() {
		time=$(date "+%H:%M, %a, %b %d ")
		out="\uf073 $time"
		echo "%{A:CALENDAR &:}$out%{A}"
	}

	sbar_ext_devices() {
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

	sbar_cloud_sync() {
		if ps -e | grep -q sshfs; then
			servername=$(cat $XDG_CONFIG_HOME/darchbox/configs | grep -w sshserver | awk '{print $2}')
			out="%{A:ef_ssh_cloud &:}%{F#1E90FF}\uf0c2 %{F-}%{A}"
		else
			out="\uf0c2 "
		fi
		echo $out
	}

	while true; do
		sbar="
		%{l}
		$(sbar_menu)
		$(sbar_ext_devices)
		%{r}
		$(sbar_update_arch)
		$(sbar_cloud_sync)
		$(sbar_cpu)
		$(sbar_mem)
		$(sbar_battery)
		$(sbar_sound_volume)
		$(sbar_backlight)
		$(sbar_bluetooth)
		$(sbar_wifi)
		$(sbar_vpn)
		$(sbar_my_uptime)
		$(sbar_clock)"
		echo -e $sbar
		sleep 0.5
	done | lemonbar -a 100 -B $BGCOLOR -F $FGCOLOR -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash

}

export -f ef_statusbar
