
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
  picom
  gvfs
  udiskie
  inotify-tools
  btop
  pavucontrol-gtk2
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
  rofi
  xf86-input-synaptics
  polybar
  wmctrl
  pactl
  dialog
  libnotify
  slock
  spacefm-bin
  xarchiver
  flameshot
  mirage
  gsimplecal
  galculator
  geany
  nano
  rate-mirrors-bin
  xbindkeys
  vimix-cursors
  ufw
  firejail
  timeshift
  cups
  sane
  sane-airscan
  ipp-usb
  xsane
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
sudo systemctl enable cups.service
sudo systemctl enable ufw.service
sudo systemctl enable ipp-usb.service

sudo ufw enable
sudo rfkill unblock bluetooth

# add user to group video to control backlight with program light

sudo gpasswd -a $USER video

# COPY CONFIGURATION FILES

cp -r filesystem/home/user/. $HOME
sudo cp filesystem/etc/X11/xorg.conf.d/70-synaptics.conf /etc/X11/xorg.conf.d/

# take a system snapshot

sudo timeshift --create --comments "Genesis"

echo "Finished! Reboot."
