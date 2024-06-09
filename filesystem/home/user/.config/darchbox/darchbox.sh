#!/bin/bash

# PATHS

XDG_CONFIG_HOME=$HOME/.config

# DEVICES

WIFIDEVICE=$(nmcli device status | awk '$2=="wifi"{print $1}')

# FILES

CONFIG_FILES_LIST="$XDG_CONFIG_HOME/openbox/* $XDG_CONFIG_HOME/darchbox/* $HOME/.config/gtk-3.0/settings.ini $HOME/.gtkrc-2.0 $HOME/.bashrc $HOME/.Xresources $HOME/.xinitrc $XDG_CONFIG_HOME/polybar/* $XDG_CONFIG_HOME/polybar/scripts/* $XDG_CONFIG_HOME/rofi/*"


# FUNCS

rofi_hmenu() {
	rofi -dmenu -theme $XDG_CONFIG_HOME/rofi/hmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary -kb-row-down 'Alt-Tab,Alt+Down,Down' -kb-row-up 'Alt+ISO_Left_Tab,Alt+Up,Up'
}

rofi_vmenu() {
	rofi -dmenu -theme $XDG_CONFIG_HOME/rofi/vmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary -no-fixed-num-lines -kb-row-down 'Alt-Tab,Alt+Down,Down' -kb-row-up 'Alt+ISO_Left_Tab,Alt+Up,Up'
}

cycle_windows() {
        if [ $(wmctrl -l | awk '{print $2}' | grep 0 | wc -l) -gt 1 ]; then
                rofi -show window -theme ~/.config/rofi/vmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary -no-fixed-num-lines -kb-cancel "Alt+Escape,Escape" -kb-accept-entry '!Alt-Tab,!Alt+Down,!Alt+ISO_Left_Tab,!Alt+Up,Return,!Alt+Alt_L' -kb-row-down 'Alt-Tab,Alt+Down,Down' -kb-row-up 'Alt+ISO_Left_Tab,Alt+Up,Up'
        fi
}

edge_to_cycle() {
        while true; do
            eval $(xdotool getmouselocation --shell)
            if [ "$Y" -le 0 ]; then
                cycle_windows
            fi
            sleep 0.2 
        done
}

keybindings() {
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

wallpaper() {
	
	list_files=$(ls ~/wallpapers)
	random_file=$(echo $list_files | tr " " "\n" | shuf -n 1)
	feh --bg-fill ~/wallpapers/$random_file
	
}

refresh() {	
	openbox --reconfigure
	killall -SIGUSR2 polybar
	sleep 0.1
	polybar
}

launcher(){
	rofi -show drun -theme $XDG_CONFIG_HOME/rofi/hmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary
}

terminal() {
        if ! tmux info &> /dev/null; then
                byobu new-session -d -s base_session
        fi
        if [ -n "$1" ]; then
                byobu new-window -t base_session "$@"
        fi
        if wmctrl -l | grep -q "byobu"; then
                term_window=$( wmctrl -l | grep "byobu" | awk '{print $1}')
                wmctrl -i -r $term_window -t $(wmctrl -d | grep '*' | cut -d ' ' -f 1)
                wmctrl -i -a $term_window
        else
                xterm byobu
        fi
}

install_packages() {
	flag=false
	PKGS=()
	while read -r line; do
                PKGS+=("$line" "" off)
	done < $XDG_CONFIG_HOME/darchbox/pkgs
	SELECTION_INSTALL=$(dialog --title "Install packages" --separate-output --checklist "Select packages:" 20 60 14 "${PKGS[@]}" 3>&1 1>&2 2>&3)
	clear
	for PKG in ${SELECTION_INSTALL[@]}; do
	yay -S --needed --noconfirm $PKG
	done
}

search() {	
	options="$(find $HOME -type f -printf '%f\n')"
	chosen="$(echo -e "$options" | rofi_hmenu)"
	xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"
}

bluetooth() {
	devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
	selection=$(echo "$devices" | rofi_hmenu)

	if [ -n "$selection" ]; then
		mac=$(echo "$selection" | cut -f1 -d' ')
		echo -e "connect $mac\nquit" | bluetoothctl
	fi
}

network() {
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

exit_menu() {
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

function run_after_network() {
    target="$1"
    interval="$2"
    while ! ping -q -c 1 -W 1 "$target" > /dev/null; do
        sleep "$interval"
    done
    shift 2
    eval "$@"
}

setup_env() {
        udiskie --no-notify &
        picom &
        polybar &
        wallpaper &
        edge_to_cycle &
}

# COMMANDS

case $1 in
        "--keybindings") keybindings;;
        "--wallpaper") wallpaper;;
        "--refresh") refresh;;
        "--launcher") launcher;;
        "--terminal") terminal ${@:2};;
        "--updatearch") terminal yay;;
        "--bluetooth") bluetooth;;
        "--network") network;;
        "--search") search;;
        "--runafternet") run_after_network ${@:2};;
        "--setupenv") setup_env;;
        "--installpackages") terminal ". $0; install_packages";;
        "--configs") geany -i $CONFIG_FILES_LIST;;
        "--cyclewindows") cycle_windows;;
        "--exit") exit_menu;;
                
        "--taskmanager") terminal btop;;
        "--editor") geany -i ${@:2};;
        "--filemanager") spacefm -r;;
        "--soundcontrol") pavucontrol;;
        "--displays") arandr;;
        "--screenshot") flameshot gui;;
        "--calculator") galculator;;
esac
