#!/bin/bash

UPDATES=$(yay -Qu 2>/dev/null | wc -l)

if [ $? -eq 0 ] && [ $UPDATES -gt 0 ]; then
    echo "●︎"
else
    echo " "
fi

case $1 in
        "--update") dab -u;;
esac
