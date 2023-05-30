#!/bin/bash

list_files=$(ls ~/wallpapers)
random_file=$(echo $list_files | tr " " "\n" | shuf -n 1)
echo $random_file
feh --bg-fill ~/wallpapers/$random_file
