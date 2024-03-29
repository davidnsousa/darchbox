
#!/bin/bash

root_dir=$(pwd)

# PKGS FOR DE

PKGS=(
    base-devel
    xorg-server
    xorg-xinit
    xorg-xkill
    xorg-xev
    xdg-utils
    xterm
    byobu
    xcompmgr
    gvfs
    udiskie
    inotify-tools
    rsync
    sshfs
    fuse2
    btop
    pavucontrol
    networkmanager
    light
    openbox-arc-git
    arc-solid-gtk-theme
    arc-icon-theme
    ttf-dejavu
    bluez
    bluez-utils
    man-db
    arandr
    dunst
    tint2
    rofi
    xf86-input-synaptics
    ttf-font-awesome
    lemonbar-xft-git
    wmctrl
    pactl
    feh
    dialog
    libnotify
    slock
    surf
    neofetch
    spacefm
    xarchiver
    flameshot
    mirage
    geany
)

# INSTALL yay

which yay || (
  cd $HOME
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  yay --save --nocleanmenu --nodiffmenu
  cd $root_dir
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

# import wallpapers

cd $HOME
git clone https://github.com/davidnsousa/wallpapers

echo "Finished! Reboot."
