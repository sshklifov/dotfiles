#!/bin/bash

idx=1
for ws in $(i3-msg -t get_workspaces | jq '.[] | .num' | sort); do
    if [ $ws -gt $idx ]; then
        break;
    fi
    idx=$((idx+1))
done

if [ "$1" == "shift" ]; then
    i3-msg "move to workspace $idx; workspace $idx"
else
    i3-msg "workspace $idx"
fi
