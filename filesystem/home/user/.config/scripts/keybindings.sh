#!/bin/bash

CONFIG_FILE=$XDG_CONFIG_HOME/openbox/rc.xml

output=$(awk -F'[<>"]+' '/<!--kb/ {comment=substr($2, 6); gsub(/-+$/, "", comment)} /<keybind/ {if (comment) {key=$4; print "(" key ") " comment; comment=""}}' "$CONFIG_FILE")

echo "$output" | dmenu -l 40 -nb $(cat $COLORS | grep -w BGCOLOR | awk '{print $2}') -nf $(cat $COLORS | grep -w FGCOLOR | awk '{print $2}') -sb $(cat $COLORS | grep -w COLOR | awk '{print $2}') -fn 'DejaVu Sans:size=9.6'
