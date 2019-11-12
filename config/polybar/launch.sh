#!/bin/bash

#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Start on all monitors
# MONITOR="HDMI-1" FOCUSED="#7b5e7d" polybar
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    i3-msg exec "MONITOR=$m polybar top"
done
