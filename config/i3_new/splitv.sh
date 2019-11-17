#!/bin/bash

filter='select(.change == "new") | .container.window'
read newid < <(i3-msg -t subscribe -m '["window"]' | jq --unbuffered "$filter")

filter='recurse(.nodes[]) | select(has("marks") and any(.marks[]; .=="splitv")) | .window'
oldid=$(i3-msg -t get_tree | jq "$filter")

i3-msg "[id=$oldid] split horizontal"
i3-msg "[id=$newid] split horizontal"
i3-msg "unmark vsplit"
