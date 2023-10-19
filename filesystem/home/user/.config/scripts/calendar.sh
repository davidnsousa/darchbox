#!/bin/bash

date=$(dialog --stdout \
  --title "Calendar" \
  --ok-label "Copy" \
  --calendar "Select date" 0 0 \
  --colors "$COLOR/$BGCOLOR")


if [ -n "$date" ]; then
  echo -n "$date" | xclip -selection clipboard
  clear
fi
