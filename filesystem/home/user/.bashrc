PS1='\[\033[1;34m\]\w\[\033[0m\] > '

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[1;5D": "cd_up\n"'
bind '"\e[1;5C": "ls_folders\n"'

cd_up() {
    cd ..
    printf "\033[1A\033[0K" # Move cursor up one line and clear it
}

ls_folders() {
    ls --color
}

if ! pgrep Xorg > /dev/null; then
    startx
fi
