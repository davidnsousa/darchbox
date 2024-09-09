#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

xset s off
xset -dpms
xset s noblank

dab() {
    ~/.config/darchbox/darchbox.sh $@
};

export -f dab

xbindkeys &
udiskie --no-notify &
picom &
if [ "$(grep 'random_wallpaper_on_startup' ~/.config/darchbox/settings | sed 's/^[^ ]* //')" == "true" ]; then
    dab -rw &
else
    nitrogen --restore &
fi &
if [ "$(grep 'vpn_autostart' ~/.config/darchbox/settings | sed 's/^[^ ]* //')" == "true" ]; then
        $(grep 'vpn_connect' ~/.config/darchbox/settings | sed 's/^[^ ]* //')
fi &
polybar &
~/.config/darchbox/autostart.sh &
dab -ran "~/.config/darchbox/autostart_online.sh" &

# start desktop environment

exec openbox-session
