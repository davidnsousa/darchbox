#!/bin/bash

if [ -e $HOME/.pixabay_api ]; then
    api_key=$(cat $HOME/.pixabay_api)
	keyword="mountains"
	urls=($(curl -s "https://pixabay.com/api/?key=$api_key&q=$keyword&order=popular&orientation=horizontal&page=1&per_page=200" | jq -r '.hits[] | select(has("largeImageURL")) | .largeImageURL'))
	rand=$[$RANDOM % ${#urls[@]}]
	rand_url=${urls[$rand]}
	wget -q -O .wallpaper.jpg $rand_url
	feh --bg-fill ~/.wallpaper.jpg
else
    notify-send -u normal "~/.pixabay_api missing ..."
fi
