#!/bin/bash

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
