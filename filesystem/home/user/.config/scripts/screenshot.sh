#!/bin/bash

if [ ! -d ~/screenshots ]; then
  mkdir ~/screenshots
fi

timestamp=$(date +%Y-%m-%d_%H-%M-%S)
screenshot_file=~/screenshots/screenshot_$timestamp.png
scrot $screenshot_file
$IMGVIEWER $screenshot_file
