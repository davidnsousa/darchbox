#!/bin/bash

options="$(find $HOME -type f -printf '%f\n')"

chosen="$(echo -e "$options" | dmenu -nb '#383c4a' -nf '#ffffff' -sb '#5294e2' -fn 'DejaVu Sans:size=9.6' -p "Search ~:")"

xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"
