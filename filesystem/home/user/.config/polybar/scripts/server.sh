#!/bin/bash

status() {
    if ps -e | grep -q sshfs; then
        servername=$(mount | grep sshfs | awk -F'[@:]' '{print $2}')
        echo "$servername"
    else
        echo "Disconnected"
    fi
}

connect() {
    servername=$(mount | grep sshfs | awk -F'[@:]' '{print $2}')
    darchbox --terminal "ssh dnsousa.com"
}

case $1 in
	"--status") status;;
    "--connect") connect;;
esac
