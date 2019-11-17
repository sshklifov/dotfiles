#!/bin/bash

focused=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')
other=$1
tmp="0"

i3-msg "rename workspace $focused to $tmp"
i3-msg "rename workspace $other to $focused" &> /dev/null
i3-msg "rename workspace $tmp to $other"
