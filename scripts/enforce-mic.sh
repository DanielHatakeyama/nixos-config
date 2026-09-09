#!/usr/bin/env bash

# Microphone Priority Enforcer
# Ensures laptop mic is always default, even if Bluetooth tries to take over
# Usage: enforce-mic.sh [--daemon]

ALSA_MIC="alsa_input.pci-0000_00_1f.3.analog-stereo"

# If --daemon passed, run in background
if [ "$1" = "--daemon" ]; then
    exec 0</dev/null
    exec 1>/tmp/enforce-mic.log
    exec 2>&1
    nohup "$0" >/dev/null 2>&1 &
    exit 0
fi

while true; do
    CURRENT=$(pactl get-default-source 2>/dev/null)
    
    # If not set to ALSA mic, force it
    if [[ "$CURRENT" != "$ALSA_MIC" ]]; then
        pactl set-default-source "$ALSA_MIC" 2>/dev/null
        echo "$(date '+%T') - Switched mic back to: ALSA"
    fi
    
    sleep 2
done

# Microphone Priority Enforcer
# Ensures laptop mic is always default, even if Bluetooth tries to take over
# Resets every 2 seconds to fight Bluetooth auto-connection

ALSA_MIC="alsa_input.pci-0000_00_1f.3.analog-stereo"

while true; do
    CURRENT=$(pactl get-default-source 2>/dev/null)
    
    # If not set to ALSA mic, force it
    if [[ "$CURRENT" != "$ALSA_MIC" ]]; then
        pactl set-default-source "$ALSA_MIC" 2>/dev/null
        echo "$(date '+%T') - Switched mic back to: ALSA"
    fi
    
    sleep 2
done
