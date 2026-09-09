#!/usr/bin/env bash

# Audio Output Switcher for Hyprland + PipeWire
# Easily switch between speakers, HDMI outputs, and other audio devices
# Supports both wpctl and pactl backends
#
# Usage:
#   audio-switch.sh speakers    # Switch to laptop speakers
#   audio-switch.sh monitor     # Switch to primary HDMI/monitor
#   audio-switch.sh toggle      # Toggle between last two outputs
#   audio-switch.sh list        # List all available outputs

# Prefer pactl if available (more reliable), fall back to wpctl
USE_PACTL=true
command -v pactl >/dev/null 2>&1 || USE_PACTL=false

# Get current default sink using pactl
get_default_sink_pactl() {
    pactl get-default-sink
}

# Switch to a specific sink using pactl
switch_sink_pactl() {
    local sink_name="$1"
    pactl set-default-sink "$sink_name"
}

# Notify user of the switch
notify_switch() {
    local device="$1"
    command -v notify-send >/dev/null 2>&1 && notify-send "Audio Output" "Switched to: $device" -t 2000
}

# Find sink by keyword (case insensitive)
find_sink_by_keyword() {
    local keyword="$1"
    
    if [ "$USE_PACTL" = true ]; then
        pactl list short sinks | grep -i "$keyword" | awk '{print $2}' | head -1
    else
        wpctl status | grep -i "$keyword" | awk '{print $NF}' | tr -d '[]' | head -1
    fi
}

# Get display name for a sink
get_sink_display_name() {
    local sink_name="$1"
    
    if [ "$USE_PACTL" = true ]; then
        # Extract the friendly name from the full sink name
        echo "$sink_name" | sed 's/.*__//;s/__sink.*//' | sed 's/_/ /g' | sed 's/HiFi //g'
    else
        echo "$sink_name"
    fi
}

case "${1,,}" in
    speakers|speaker|internal|laptop|built-in)
        # Switch to built-in speakers
        if [ "$USE_PACTL" = true ]; then
            sink=$(find_sink_by_keyword "speaker")
            if [ -z "$sink" ]; then
                echo "Error: Speaker sink not found"
                exit 1
            fi
            switch_sink_pactl "$sink"
            display_name=$(get_sink_display_name "$sink")
            notify_switch "$display_name"
            echo "✓ Switched to: $display_name"
        else
            echo "Error: pactl not found, please install pulseaudio"
            exit 1
        fi
        ;;
    
    monitor|hdmi|hdmi1|hdmi2|hdmi3|display|external|displayport|dp)
        # Switch to first available HDMI/monitor
        if [ "$USE_PACTL" = true ]; then
            sink=$(find_sink_by_keyword "hdmi")
            if [ -z "$sink" ]; then
                sink=$(find_sink_by_keyword "displayport")
            fi
            if [ -z "$sink" ]; then
                echo "Error: HDMI/Display sink not found"
                exit 1
            fi
            switch_sink_pactl "$sink"
            display_name=$(get_sink_display_name "$sink")
            notify_switch "$display_name"
            echo "✓ Switched to: $display_name"
        else
            echo "Error: pactl not found, please install pulseaudio"
            exit 1
        fi
        ;;
    
    toggle)
        # Toggle between speaker and primary HDMI
        if [ "$USE_PACTL" = true ]; then
            current=$(get_default_sink_pactl)
            
            if echo "$current" | grep -iq "speaker"; then
                # Currently on speaker, switch to HDMI
                sink=$(find_sink_by_keyword "hdmi")
                if [ -z "$sink" ]; then
                    sink=$(find_sink_by_keyword "displayport")
                fi
                if [ -z "$sink" ]; then
                    echo "Error: No HDMI sink found to toggle to"
                    exit 1
                fi
                switch_sink_pactl "$sink"
                display_name=$(get_sink_display_name "$sink")
                notify_switch "$display_name"
                echo "✓ Switched to: $display_name"
            else
                # Currently on HDMI, switch to speaker
                sink=$(find_sink_by_keyword "speaker")
                if [ -z "$sink" ]; then
                    echo "Error: No Speaker sink found to toggle to"
                    exit 1
                fi
                switch_sink_pactl "$sink"
                display_name=$(get_sink_display_name "$sink")
                notify_switch "$display_name"
                echo "✓ Switched to: $display_name"
            fi
        else
            echo "Error: pactl not found, please install pulseaudio"
            exit 1
        fi
        ;;
    
    list|ls|--list)
        # List all available audio outputs
        echo "📻 Available Audio Outputs:"
        echo ""
        if [ "$USE_PACTL" = true ]; then
            pactl list short sinks | nl -w 2 -s '. ' | while read line; do
                echo "  $line"
            done
            echo ""
            current=$(get_default_sink_pactl)
            echo "✓ Current default: $current"
        else
            echo "Error: pactl not found, please install pulseaudio"
            exit 1
        fi
        ;;
    
    "")
        # No argument - show help
        echo "🔊 Audio Output Switcher for Hyprland + PipeWire"
        echo ""
        echo "Usage: audio-switch.sh [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  speakers               Switch to built-in speakers"
        echo "  monitor                Switch to monitor/HDMI output"
        echo "  toggle                 Toggle between speaker and monitor"
        echo "  list                   List all available outputs"
        echo ""
        echo "Examples:"
        echo "  audio-switch.sh speakers   # Use laptop speakers even with HDMI connected"
        echo "  audio-switch.sh monitor    # Use external monitor audio"
        echo "  audio-switch.sh toggle     # Quick switch between outputs"
        echo ""
        echo "Hyprland Keybindings:"
        echo "  Super+F1               Switch to speakers"
        echo "  Super+F2               Switch to monitor"
        echo "  Super+F3               Toggle between outputs"
        echo ""
        echo "Shell Aliases:"
        echo "  audio                  Open PulseAudio Volume Control GUI"
        echo "  audio-list             List available outputs"
        ;;
    
    *)
        # Try to switch to sink by exact name or number
        if [ "$USE_PACTL" = true ]; then
            if pactl list short sinks | awk '{print $2}' | grep -q "^${1}$"; then
                # Argument is a sink name
                switch_sink_pactl "$1"
                display_name=$(get_sink_display_name "$1")
                notify_switch "$display_name"
                echo "✓ Switched to: $display_name"
            else
                echo "❌ Error: Unknown command or sink '$1'"
                echo "Run: audio-switch.sh --list"
                exit 1
            fi
        else
            echo "❌ Error: Unknown command '$1'"
            echo "Run: audio-switch.sh --list"
            exit 1
        fi
        ;;
esac
