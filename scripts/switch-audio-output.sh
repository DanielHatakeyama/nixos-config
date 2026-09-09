#!/usr/bin/env bash

# Audio output switching script for Hyprland

case "$1" in
    "speakers"|"headphones")
        # Switch to computer speakers/headphones
        SINK_ID=$(wpctl status | grep -A20 "Sinks:" | grep -E "(Speaker|Headphones)" | head -1 | awk '{print $2}' | sed 's/\.//')
        if [ -n "$SINK_ID" ]; then
            wpctl set-default "$SINK_ID"
            notify-send "Audio Output" "Switched to Computer Speakers" -t 2000
        else
            notify-send "Audio Output" "Computer speakers not found" -t 2000
        fi
        ;;
    "monitor"|"hdmi"|"external")
        # Switch to external monitor/HDMI
        SINK_ID=$(wpctl status | grep -A20 "Sinks:" | grep -E "(HDMI|DisplayPort)" | head -1 | awk '{print $2}' | sed 's/\.//')
        if [ -n "$SINK_ID" ]; then
            wpctl set-default "$SINK_ID"
            notify-send "Audio Output" "Switched to External Monitor" -t 2000
        else
            notify-send "Audio Output" "External monitor audio not found" -t 2000
        fi
        ;;
    "toggle")
        # Toggle between speakers and monitor
        CURRENT_DEFAULT=$(wpctl status | grep -A20 "Sinks:" | grep "\*" | head -1)
        if echo "$CURRENT_DEFAULT" | grep -q "HDMI\|DisplayPort"; then
            # Currently on monitor, switch to speakers
            "$0" speakers
        else
            # Currently on speakers, switch to monitor
            "$0" monitor
        fi
        ;;
    *)
        echo "Usage: $0 {speakers|monitor|toggle}"
        echo "  speakers - Switch to computer speakers/headphones"
        echo "  monitor  - Switch to external monitor audio"
        echo "  toggle   - Toggle between speakers and monitor"
        exit 1
        ;;
esac
