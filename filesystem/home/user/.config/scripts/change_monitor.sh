#!/bin/bash

primary_monitor=$(xrandr --listmonitors | tail -n +2 | grep '*' | awk '{print $NF}')
if [ $(xrandr | grep $HDMI | awk '{print $2}') = 'connected' ]; then
	if [ $primary_monitor != $HDMI ]; then
		xrandr --output $DP --off
		xrandr --output $HDMI --auto --primary
	elif [ $primary_monitor = $HDMI ]; then
		xrandr --output $HDMI --off
		xrandr --output $DP --auto --primary
	fi
fi

bash $XDG_CONFIG_HOME/scripts/refresh.sh
