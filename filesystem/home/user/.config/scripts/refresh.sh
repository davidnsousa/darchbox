#!/bin/bash

openbox --reconfigure
killall -SIGUSR2 lemonbar
sleep 0.1
bash $XDG_CONFIG_HOME/scripts/statusbar.sh
bash $XDG_CONFIG_HOME/scripts/taskbar.sh
