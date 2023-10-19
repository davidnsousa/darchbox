#!/bin/bash

options="$(find $HOME -type f -printf '%f\n')"

chosen="$(echo -e "$options" | eval "dmenu -nb '$(cat $COLORS | grep -w BGCOLOR | awk '{print $2}')' -nf '$(cat $COLORS | grep -w FGCOLOR | awk '{print $2}')' -sb '$(cat $COLORS | grep -w COLOR | awk '{print $2}')' -fn 'DejaVu Sans:size=9.6' -p 'Search ~:'")"

xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"
