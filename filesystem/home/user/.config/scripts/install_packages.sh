#!/bin/bash

PKGS=()
while read -r pkg; do
  PKGS+=("$pkg" "" off)
done < $XDG_CONFIG_HOME/scripts/packages

SELECTION_INSTALL=$(dialog --title "Install packages" --separate-output --checklist "Select packages:" 20 60 14 "${PKGS[@]}" 3>&1 1>&2 2>&3)
clear
for PKG in ${SELECTION_INSTALL[@]}; do
    yay -S --needed $PKG
done
