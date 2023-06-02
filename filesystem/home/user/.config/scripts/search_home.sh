#!/bin/bash

options="$(find $HOME -type f -printf '%f\n')"

chosen="$(echo -e "$options" | eval "dmenu $DMENU_ARGS -p 'Search ~:'")"

xdg-open "$(find $HOME -type f -name "$chosen" -print -quit)"
