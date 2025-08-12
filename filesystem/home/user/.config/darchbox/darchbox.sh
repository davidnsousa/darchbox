#!/bin/bash

# PATHS

XDG_CONFIG_HOME=$HOME/.config

# DEVICES

WIFIDEVICE=$(nmcli device status | awk '$2=="wifi"{print $1}')

# FILES

CONFIG_FILES_LIST="$XDG_CONFIG_HOME/openbox/rc.xml $XDG_CONFIG_HOME/darchbox/* $HOME/.config/gtk-3.0/settings.ini $HOME/.gtkrc-2.0 $HOME/.bashrc $HOME/.Xresources $HOME/.xinitrc $HOME/.xbindkeysrc $XDG_CONFIG_HOME/polybar/* $XDG_CONFIG_HOME/polybar/scripts/* $XDG_CONFIG_HOME/rofi/* $XDG_CONFIG_HOME/dunst/*"
BASIC_CONFIG_FILES_LIST="$XDG_CONFIG_HOME/darchbox/autostart* $XDG_CONFIG_HOME/darchbox/settings $HOME/.xbindkeysrc $XDG_CONFIG_HOME/polybar/*"

# FUNCS

rofi_hmenu() {
	rofi -dmenu -p "$1" -theme $XDG_CONFIG_HOME/rofi/hmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary  -monitor 1
}

rofi_hmenu_i() {
	rofi -dmenu -p "$1" -theme $XDG_CONFIG_HOME/rofi/hmenu.rasi rofi -theme-str '#element selected { background-color: #75507B; }' -hover-select -me-select-entry '' -me-accept-entry MousePrimary -monitor 1
}

rofi_vmenu() {
	rofi -dmenu -p "$1" -theme $XDG_CONFIG_HOME/rofi/vmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary -no-fixed-num-lines -kb-row-down 'Alt-Tab,Alt+Down,Down' -kb-row-up 'Alt+ISO_Left_Tab,Alt+Up,Up' -monitor 1
}

cycle_windows() { 
        if [ $(wmctrl -l | awk '{print $2}' | grep 0 | wc -l) -ge 1 ]; then
                rofi -show window  -theme ~/.config/rofi/hmenu.rasi -hover-select -me-select-entry '' -me-accept-entry MousePrimary -no-fixed-num-lines -kb-cancel "Alt+Escape,Escape" -kb-accept-entry '!Alt-Tab,!Alt+Down,!Alt+ISO_Left_Tab,!Alt+Up,Return,!Alt+Alt_L' -kb-row-down 'Alt-Tab,Alt+Down,Down' -kb-row-up 'Alt+ISO_Left_Tab,Alt+Up,Up' -selected-row 1 -steal-focus -show-icons -window-format {t:15} -monitor 1;
        fi
}

keybindings() {
        input=$(cat $HOME/.xbindkeysrc)
        output=""

        while IFS= read -r line; do
            if [[ $line == \#\>* ]]; then
                description=${line//\#>/}
            elif [[ $line == \"*\" ]]; then
                command=${line//\"/}
            elif [[ "$line" ]] && [[ -n $description ]]; then
                keybinding=${line//\"/}
                output+="[${keybinding}] ${description} (${command})\n"
                description=""
            fi
        done <<< "$input"

        selected_key=$(printf "$output" | rofi_vmenu "Action:") 
        if [ -n "$selected_key" ]; then
                sleep 0.1
                command=$(echo "$selected_key" | awk -F"[()]" '{print $2}')
                eval "$command"
        fi
}

refresh() {
        openbox --reconfigure
        xbindkeys
	killall -SIGUSR2 polybar
	sleep 0.1
	polybar
}

launcher(){
        app=$(compgen -c | rofi_hmenu "Run:")
        $app &
}

sandbox(){
        app=$(compgen -c | rofi_hmenu_i "Sandbox:")
        if [ -n "$app" ]; then
            firejail --whitelist=${HOME}/Downloads "$app"
        fi
}

terminal() {
        if wmctrl -l | grep -q -e "byobu"; then
                term_window=$( wmctrl -l | grep -e "byobu" | awk '{print $1}')
                wmctrl -i -r $term_window -t $(wmctrl -d | grep '*' | cut -d ' ' -f 1)
                wmctrl -i -a $term_window
        else
            xterm byobu & sleep 0.5 
            byobu-tmux select-window -t :-
        fi
        if ! tmux info &> /dev/null; then
                byobu
        fi
        if [ -n "$1" ]; then
                byobu new-window "$@"
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
	chosen="$(echo -e "$options" | rofi_hmenu 'Search ~:'  )"
	xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"
}

bluetooth() {
	devices=$(bluetoothctl devices | grep "Device" | cut -f2- -d' ')
	selection=$(echo -e "$devices\nbluetoothctl\nToggle" | rofi_hmenu "Bluetooth:")

	if [ -n "$selection" ]; then
                if [ "$selection" == "bluetoothctl" ]; then
                        terminal bluetoothctl
                elif [ "$selection" == "Toggle" ]; then
                        bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on
                else
                        mac=$(echo "$selection" | cut -f1 -d' ')
                        echo -e "connect $mac\nquit" | bluetoothctl
                fi
	fi
}

wifi_menu() {	
        selected=$(nmcli -t -f ssid dev wifi | grep -E -v '^$' | rofi_hmenu "Wi-fi:")

        if [[ -n "$selected" ]]; then
                if nmcli -s -g 802-11-wireless-security.psk connection show "$selected" 2>&1 | grep -q "no such connection profile"; then
                        password=$(echo "" | rofi_hmenu "Password:")
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

network() {
        option=$(echo -e "Wifi connections\nConnect/Disconnect Wi-Fi\nEnable/Disable Wi-Fi\nEnable/Disable Networking" | rofi_hmenu "Network:")
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

	chosen="$(echo -e "$options" | rofi_hmenu "System:" )"
	case $chosen in
                $option0)
                        slock;;
                $option1)
                        pkill -u $USER X;;
                $option2)
                        reboot;;
                $option3)
                        shutdown now;;
        esac
}

configurations() {
        geany -i $CONFIG_FILES_LIST
}

run_after_network() {
    while ! ping -q -c 1 -W 1 ping.eu > /dev/null; do
        sleep 5
    done
    eval "$@"
}

update_mirrors() {
        rate-mirrors --allow-root --protocol https arch | grep -v '^#' | sudo tee /etc/pacman.d/mirrorlist
        notify-send "Mirrors set!"
}

# COMMANDS

case $1 in
        "-k") keybindings;;
        "-r") refresh;;
        "-l") launcher;;
        "-srun") sandbox;;
        "-t") terminal ${@:2};;
        "-u") terminal yay;;    
        "-b") bluetooth;;
        "-n") network;;
        "-w") wifi_menu;;
        
        "-s") search;;
        "-ran") run_after_network ${@:2};;
        "-se") setup_env;;
        "-c") configurations;;
        "-em") exit_menu;;
        "-lck") slock;;
                
        "-tm") terminal btop;;
        "-e") geany -i ${@:2};;
        "-f") nemo --existing-window;;
        "-sc") pavucontrol;;
        "-d") arandr;;
        "-ss") flameshot gui;;
        "-ca") galculator;;
        "-su") pactl set-sink-volume @DEFAULT_SINK@ +0.1;;
        "-sd") pactl set-sink-volume @DEFAULT_SINK@ -0.1;;
        "-sm") pactl set-sink-mute @DEFAULT_SINK@ toggle;;
        "-bu") light -A 5;;
        "-bd") light -U 5;;
        "-kw") wmctrl -c :ACTIVE:;;
        "-sde") wmctrl -k on;;
        "-cw") cycle_windows;;
        
        "-um") update_mirrors;;
        "-ip") install_packages;;

esac
