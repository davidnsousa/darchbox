# Arch Linux Post Installation Setup Script

darchbox installs the Pacman wrapper and AUR helper yay, updates the system, and sets up a basic desktop environment including openbox, dmenu and lemonbar.

[setup.sh](setup.sh) describes the installation procedure and the software included. All main DE features can be controlled with the key bindings (Super+k lists the key bindings) and from the statusbar and taskbar with left and/or right clicks on the icons. Mounted external devices are shown and can be accessed from the statusbar. The [configuration files](filesystem/home/user/) located in ~ and downstream control the entire DE.

### Usage

Requires Arch linux.

```
git clone --depth 1 https://github.com/davidnsousa/darchbox
cd darchbox
bash setup.sh
```

![alt text](https://i.imgur.com/74sATEw.png "darchbox desktop")
