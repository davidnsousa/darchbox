#!/bin/bash

CONFIG_FILE=$XDG_CONFIG_HOME/openbox/rc.xml

output=$(awk -F'[<>"]+' '/<!--kb/ {comment=substr($2, 6); gsub(/-+$/, "", comment)} /<keybind/ {if (comment) {key=$4; print "(" key ") " comment; comment=""}}' "$CONFIG_FILE")

echo "$output" | dmenu -l 40 -nb '#383c4a' -nf '#ffffff' -sb '#383c4a' -fn 'DejaVu Sans:size=9.6'
