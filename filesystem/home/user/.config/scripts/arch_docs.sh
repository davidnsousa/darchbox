#!/bin/bash

search_term=$(curl -sS "https://wiki.archlinux.org/title/Table_of_contents" | grep -o '<a href="/title/Category:[^>]*>[^<]*</a>' | sed 's/<[^>]*>//g' | eval "dmenu $DMENU_ARGS -p 'Search Arch docs:'")

surf "https://wiki.archlinux.org/index.php?search=${search_term}"
