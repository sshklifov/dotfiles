#!/bin/bash
left="HDMI-1"
right="DP-0"

if [ "$1" == "shift" ]; then
    templ="move output #; focus output #"
else
    templ="focus output #"
fi

curr=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true) | .output')

if [ "$curr" == "$left" ]; then
    cmd=$(sed -e "s/#/$right/g" <<< $templ)
else
    cmd=$(sed -e "s/#/$left/g" <<< $templ)
fi

i3-msg "$cmd"
