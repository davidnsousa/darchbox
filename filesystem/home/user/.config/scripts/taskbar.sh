#!/bin/bash

chosen_icon() {
	window=$(wmctrl -lx | grep $1)
	if echo "$window" | grep -qE "xterm"; then
        echo "\uf2d0"
    elif echo "$window" | grep -qE "LibreWolf|firefox|mullvadbrowser"; then
		echo "\ue007"
	elif echo "$window" | grep -qE "chrome"; then
		echo "\uf268"
	elif echo "$window" | grep -qE "pcmanfm|spacefm"; then
		echo "\uf07c"
	elif echo "$window" | grep -qE "Telegram"; then
		echo "\uf2c6"
	elif echo "$window" | grep -qE "zoom"; then
		echo "\uf03d"
	elif echo "$window" | grep -qE "MEGAsync"; then
		echo "\u4d"
	elif echo "$window" | grep -qE "VirtualBox"; then
		echo "\uf49e"
	elif echo "$window" | grep -qE "Mirage"; then
		echo "\uf03e"
	elif echo "$window" | grep -qE "Gimp|Inkscape"; then
		echo "\uf1fc"
	elif echo "$window" | grep -qE "vlc"; then
		echo "\ue131"
	elif echo "$window" | grep -qE "Geany|Pulsar"; then
		echo "\uf1c9"
	elif echo "$window" | grep -qE "Surf"; then
		echo "\uf7a2"
    else
        echo "\uf15b"
    fi
}

button_state() {
    active_win=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}' | awk '{print strtonum("0x" substr($0, 3))}')
    DEC_ID1=$(printf "%d" $active_win)
    DEC_ID2=$(printf "%d" $1)
    if [ $DEC_ID1 == $DEC_ID2 ]; then
        echo "%{B$COLOR} \x20 $3 $2 \x20 %{B-}"
    else
        echo " \x20 $3 $2 \x20 "
    fi
}

launchers_taskbar() {
	echo "%{A:$TERMINAL &:} \uf120%{A} 
		%{A: $FILEMANAGER &:} \uf07c%{A}" 
}

xev -root | grep -E --line-buffered "_NET_ACTIVE_WINDOW|CreateNotify|DestroyNotify|_NET_CURRENT_DESKTOP" | while read line; do
	deskid=$(wmctrl -d | grep '*' | cut -d ' ' -f 1)
	desktops=''
	COLOR=$(cat $COLORS | grep -w COLOR | awk '{print $2}')
	for dID in $(wmctrl -d | awk '{print $1}'); do
		if [ $deskid == $dID ]; then
			dID=$((dID+1))
			desktops+="%{B$COLOR}\x20$dID\x20%{B-}"
		else
			dID=$((dID+1))
			desktops+="%{A: wmctrl -s $dID &:}\x20$dID\x20%{A}"
		fi
	done
    IDS=$(wmctrl -l | awk '$2 == "'"$deskid"'"' | awk '{print $1}')
    BAR_INPUT="%{l}$desktops %{c}"
    for ID in $IDS; do
        NAME=$(wmctrl -l | grep $ID | awk '{$1=""; $2=""; $3=""; sub(/^ */, ""); title=$0; if(length(title)>10) title=substr(title, 1, 10) " ..."; print title}')
        ICON=$(chosen_icon $ID)
        BAR_INPUT+="%{A: wmctrl -i -a $ID &:}%{A3: wmctrl -i -c $ID &:}$(button_state $ID "$NAME" "$ICON")%{A}%{A3}"
    done
    echo -e $BAR_INPUT
done | lemonbar -a 100 -b -B $(cat $COLORS | grep -w BGCOLOR | awk '{print $2}') -f "DejaVu Sans:size=9" -f 'Font Awesome 6 Free:size=10' -f 'Font Awesome 6 Brands:size=10' -f 'Font Awesome 6 Free Solid:size=10' | bash &
