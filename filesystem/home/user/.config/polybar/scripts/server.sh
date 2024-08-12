#!/bin/bash

status() {
    if ps -e | grep -q sshfs; then
        servername=$(mount | grep sshfs | awk -F'[@:]' '{print $2}')
        echo "%{F#2EBA3B}●%{F-} $servername"
    else
        echo "%{F#FF0000}●%{F-}"
    fi
}

connect() {
    servername=$(mount | grep sshfs | awk -F'[@:]' '{print $2}')
    dab -t "ssh $servername"
}

case $1 in
	"--status") status;;
    "--connect") connect;;
esac
