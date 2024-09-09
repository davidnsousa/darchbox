# Arch Linux Post Installation Setup Script

darchbox installs the Pacman wrapper and AUR helper yay, updates the system, and sets up a basic desktop environment including openbox, rofi and polybar.

[setup.sh](setup.sh) describes the installation procedure and the software included. All main DE features can be controlled with the key bindings (Super+k lists the key bindings) and from the statusbar with left and/or right clicks on the icons. The [configuration files](filesystem/home/user/) located in ~ and downstream control the entire DE.

Note: DPI and font sizes are set for QHD screens.

### Usage

Requires Arch linux.

```
git clone --depth 1 https://github.com/davidnsousa/darchbox
cd darchbox
bash setup.sh
```
