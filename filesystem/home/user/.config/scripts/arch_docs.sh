#!/bin/bash

search_term=$(curl -sS "https://wiki.archlinux.org/title/Table_of_contents" | grep -o '<a href="/title/Category:[^>]*>[^<]*</a>' | sed 's/<[^>]*>//g' | eval "dmenu -nb '$(cat $COLORS | grep -w BGCOLOR | awk '{print $2}')' -nf '$(cat $COLORS | grep -w FGCOLOR | awk '{print $2}')' -sb '$(cat $COLORS | grep -w COLOR | awk '{print $2}')' -p 'Search Arch docs:'")

if [ -n "$search_term" ]; then
    surf "https://wiki.archlinux.org/index.php?search=${search_term}"
fi


