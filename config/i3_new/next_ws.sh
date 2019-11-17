#!/bin/bash

if [ -z "$1" ]; then
    exit
fi

dowhile="true"
i3-msg -t get_workspaces | jq --unbuffered -r '.[] | select(.focused==true) | .num,.output' |
while $dowhile; do
    dowhile="false"
    read focused
    read output

    wss=$(i3-msg -t get_workspaces | jq ".[] | select(.output == \"${output}\") | .num" | sort)
    cnt=$(wc -l <<< $wss)
    idx=$(grep -n "^$focused$" <<< "$wss" | cut -d ':' -f 1)
    idx=$(((idx-1+$1+$cnt) % $cnt + 1))

    next=$(sed -n "${idx}p" <<< "$wss")
    # i3-msg workspace $next
    echo $next
done
