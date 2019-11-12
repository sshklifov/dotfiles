#!/bin/bash

SINK=0

function clamp
{
    if [ $1 -lt $2 ]; then
        echo $2
    elif [ $1 -gt $3 ]; then
        echo $3
    else
        echo $1
    fi
}

function getVolume
{
    monstrosity="s:.*\[([0-9]+)%\].*:\1:p"
    amixer -D pulse get Master | sed -rn $monstrosity | head -n 1
}

function isMute
{
    ! amixer -D pulse get Master | grep -q "\[on\]"
}

function volNotifySend
{
    if isMute || [ $vol -eq 0 ]; then
        notify-send.sh -t 1500 --icon=audio-volume-muted --replace-file=/tmp/volumenotification "$1"
    elif [ $vol -le 30 ]; then
        notify-send.sh -t 1500 --icon=audio-volume-low --replace-file=/tmp/volumenotification "$1"
    elif [ $vol -le 70 ]; then
        notify-send.sh -t 1500 --icon=audio-volume-medium --replace-file=/tmp/volumenotification "$1"
    else
        notify-send.sh -t 1500 --icon=audio-volume-high --replace-file=/tmp/volumenotification "$1"
    fi
}

case $1 in
+[0-9]*%)
    vol=$(getVolume)
    step=$(echo $1 | sed -r 's:\+([0-9]+)%:\1:')
    vol=$(clamp $((vol+step)) 0 100)

    pactl set-sink-mute $SINK false; pactl set-sink-volume $SINK "$vol%"
    volNotifySend "Volume: $vol%"
    ;;

-[0-9]*%)
    vol=$(getVolume)
    step=$(echo $1 | sed -r 's:-([0-9]+)%:\1:')
    vol=$(clamp $((vol-step)) 0 100)

    pactl set-sink-mute $SINK false; pactl set-sink-volume $SINK "$vol%"
    volNotifySend "Volume: $vol%"
    ;;

mute)
    pactl set-sink-mute $SINK toggle
    if isMute; then
        volNotifySend "Volume: muted"
    else
        vol=$(getVolume)
        volNotifySend "Volume: $vol%"
    fi
    ;;
*)
    exit 1
esac
