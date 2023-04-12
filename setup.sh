
#!/bin/bash

dlemonbox_dir=$(pwd)

# PKGS FOR DE

PKGS=(
    xorg-server
    xorg-xinit
    xorg-xkill
    xorg-xev
    xdg-utils
    xterm
    xcompmgr
    gvfs
    htop
    pavucontrol
    network-manager-applet
    light
    openbox-arc-git
    arc-solid-gtk-theme
    arc-icon-theme
    ttf-dejavu
    bluez
    bluez-utils
    blueman
    man-db
    pcmanfm
    arandr
    dunst
    mirage
    geany
    xarchiver
    xf86-input-synaptics
    gscreenshot
    ttf-font-awesome
    lemonbar-xft-git
    wmctrl
    dmenu
    pactl
    feh
    dialog
    libnotify
    slock
)

# INSTALL yay

which yay || (
  cd $HOME
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  yay --save --nocleanmenu --nodiffmenu
  cd $dlemonbox_dir
)

# UPDATE SYSTEM

yay --noconfirm

# INSTALL PKGS

for PKG in ${PKGS[@]}; do
    yay -S --needed --noconfirm $PKG
done

# ENABLE SERVICES

sudo systemctl enable NetworkManager.service
sudo systemctl enable bluetooth.service

# add user to group video to control backlight with program light

sudo gpasswd -a $USER video

# COPY CONFIGURATION FILES

cp -r filesystem/home/user/. $HOME
sudo cp filesystem/etc/X11/xorg.conf.d/70-synaptics.conf /etc/X11/xorg.conf.d/

echo "Finished!"
