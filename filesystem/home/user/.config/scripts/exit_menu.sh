#!/bin/bash

option0="Lock"
option1="Leave X"
option2="Reboot"
option3="Shutdown"

options="$option0\n$option1\n$option2\n$option3"

chosen="$(echo -e "$options" | dmenu -nb '#383c4a' -nf '#ffffff' -sb '#5294e2' -fn 'DejaVu Sans:size=9.6')"
case $chosen in
	$option0)
		slock;;
	$option1)
		openbox --exit;;
	$option2)
		reboot;;
	$option3)
		shutdown now;;
esac
