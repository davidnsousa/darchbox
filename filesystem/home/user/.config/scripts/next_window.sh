#!/bin/bash

deskid=$(wmctrl -d | grep '*' | cut -d ' ' -f 1)
IDS=($(wmctrl -l | awk '$2 == "'"$deskid"'"' | awk '{print $1}'))
wmctrl -l | awk '$2 == "0"'
while true; do
  for (( i=0; i<${#IDS[@]}; i++ )); do
    active_win=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}' | awk '{print strtonum("0x" substr($0, 3))}')
    DEC_ID1=$(printf "%d" $active_win)
    DEC_ID2=$(printf "%d" ${IDS[$i]})
    if [ $DEC_ID1 == $DEC_ID2 ]; then
      next_index=$(( (i+1) % ${#IDS[@]} ))
      wmctrl -i -a ${IDS[$next_index]}
      break 2
    fi
  done
done
