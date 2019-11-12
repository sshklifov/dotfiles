#!/bin/bash

SCREENSHOT="/tmp/screenshot.png"

if [ "$1" = "screen" ]; then
    flag=''
elif [ "$1" = "window" ]; then
    flag='-u'
elif [ "$1" = "select" ]; then
    flag='-s'
else
    exit 1
fi

scrot -o $flag $SCREENSHOT
xclip -selection clipboard -i -target image/png $SCREENSHOT
notify-send.sh -t 2000 "Screenshot taken"
