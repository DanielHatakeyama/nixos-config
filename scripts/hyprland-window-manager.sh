#!/usr/bin/env bash

# Hyprland Modal System - Replicating skhd resize and WASD modes
# Advanced window management for Hyprland

set -euo pipefail

# Configuration
RESIZE_STEP_SMALL=20
RESIZE_STEP_MEDIUM=50
RESIZE_STEP_LARGE=100
MODE_NOTIFICATION_TIME=3000

# Get current application class
get_current_app() {
    hyprctl activewindow -j | jq -r '.class' 2>/dev/null || echo ""
}

# Check if we're in an excluded application
is_excluded_app() {
    local app="$1"
    case "$app" in
        "cursor"|"Cursor"|"code"|"Code") return 0 ;;
        "zen"|"Zen"|"zen-browser") return 0 ;;
        *) return 1 ;;
    esac
}

# Send notification
notify_mode() {
    local title="$1"
    local message="$2"
    notify-send "$title" "$message" --expire-time="$MODE_NOTIFICATION_TIME" --urgency=low --app-name="Hyprland WM"
}

# Window focus with application exclusions (matching skhd behavior)
window_focus() {
    local direction="$1"
    local app=$(get_current_app)
    
    # Application-specific exclusions (matching skhd behavior)
    if is_excluded_app "$app"; then
        case "$direction" in
            "up"|"north"|"k")
                if [[ "$app" =~ [Zz]en ]]; then
                    # In Zen: Super+k should trigger Ctrl+Shift+Tab (previous tab)
                    hyprctl dispatch exec "wtype -k ctrl+shift+Tab"
                    return 0
                elif [[ "$app" =~ [Cc]ursor ]]; then
                    # Pass through - don't interfere
                    return 0
                fi
                ;;
            "down"|"south"|"j") 
                if [[ "$app" =~ [Zz]en ]]; then
                    # In Zen: Super+j should trigger Ctrl+Tab (next tab)
                    hyprctl dispatch exec "wtype -k ctrl+Tab"
                    return 0
                elif [[ "$app" =~ [Cc]ursor ]]; then
                    # Pass through - don't interfere
                    return 0
                fi
                ;;
        esac
    fi
    
    # Normal window focus using Hyprland
    case "$direction" in
        "left"|"west"|"h")
            hyprctl dispatch movefocus l
            ;;
        "right"|"east"|"l")
            hyprctl dispatch movefocus r
            ;;
        "up"|"north"|"k")
            hyprctl dispatch movefocus u
            ;;
        "down"|"south"|"j")
            hyprctl dispatch movefocus d
            ;;
    esac
}

# Modal resize system (replicating skhd resize mode)
enter_resize_mode() {
    notify_mode "Resize Mode" "Use H/L for width, J/K for height, ESC to exit
• H/L: ±${RESIZE_STEP_SMALL}px width
• Shift+H/L: ±${RESIZE_STEP_MEDIUM}px width  
• Ctrl+H/L: ±${RESIZE_STEP_LARGE}px width
• J/K: ±${RESIZE_STEP_SMALL}px height"

    # Create mode indicator file
    local mode_file="/tmp/hyprland_resize_mode"
    touch "$mode_file"
    
    # Start input capture for resize mode
    resize_mode_loop &
    local loop_pid=$!
    
    # Wait for mode to end
    while [ -f "$mode_file" ]; do
        sleep 0.1
    done
    
    kill $loop_pid 2>/dev/null || true
    notify_mode "Resize Mode" "Exited"
}

# Resize mode input loop
resize_mode_loop() {
    local mode_file="/tmp/hyprland_resize_mode"
    
    while [ -f "$mode_file" ]; do
        # Read single character
        read -n 1 -s key
        
        case "$key" in
            'h'|'H') resize_window "left" "$RESIZE_STEP_SMALL" ;;
            'l'|'L') resize_window "right" "$RESIZE_STEP_SMALL" ;;
            'j'|'J') resize_window "down" "$RESIZE_STEP_SMALL" ;;
            'k'|'K') resize_window "up" "$RESIZE_STEP_SMALL" ;;
            $'\e') rm -f "$mode_file" ;; # Escape key
            'q'|'Q') rm -f "$mode_file" ;;
            *) ;;
        esac
    done
}

# Resize window using Hyprland
resize_window() {
    local direction="$1"
    local amount="$2"
    
    case "$direction" in
        "left"|"h")
            hyprctl dispatch resizeactive -"$amount" 0
            ;;
        "right"|"l")
            hyprctl dispatch resizeactive "$amount" 0
            ;;
        "up"|"k")
            hyprctl dispatch resizeactive 0 -"$amount"
            ;;
        "down"|"j")
            hyprctl dispatch resizeactive 0 "$amount"
            ;;
    esac
}

# WASD navigation mode (replicating skhd wasd mode)  
enter_wasd_mode() {
    notify_mode "WASD Focus Mode" "Use WASD for navigation, ESC to exit
• W: Focus up/north
• A: Focus left/west → Previous workspace
• S: Focus down/south  
• D: Focus right/east → Next workspace"
    
    local mode_file="/tmp/hyprland_wasd_mode"
    touch "$mode_file"
    
    # Start input capture for WASD mode
    wasd_mode_loop &
    local loop_pid=$!
    
    # Wait for mode to end
    while [ -f "$mode_file" ]; do
        sleep 0.1
    done
    
    kill $loop_pid 2>/dev/null || true
    notify_mode "WASD Mode" "Exited"
}

# WASD mode input loop
wasd_mode_loop() {
    local mode_file="/tmp/hyprland_wasd_mode"
    
    while [ -f "$mode_file" ]; do
        read -n 1 -s key
        
        case "$key" in
            'w'|'W') wasd_navigate "w" ;;
            'a'|'A') wasd_navigate "a" ;;
            's'|'S') wasd_navigate "s" ;;
            'd'|'D') wasd_navigate "d" ;;
            $'\e') rm -f "$mode_file" ;; # Escape key
            'q'|'Q') rm -f "$mode_file" ;;
            *) ;;
        esac
    done
}

# WASD navigation with fallback chain
wasd_navigate() {
    local direction="$1"
    
    case "$direction" in
        "w") window_focus "up" ;;
        "s") window_focus "down" ;;
        "a") 
            # Chain: window → previous workspace
            if ! window_focus "left"; then
                hyprctl dispatch workspace e-1
            fi
            ;;
        "d")
            # Chain: window → next workspace  
            if ! window_focus "right"; then
                hyprctl dispatch workspace e+1
            fi
            ;;
    esac
}

# Float window and center (matching yabai grid 4:4:1:1:2:2)
float_toggle() {
    hyprctl dispatch togglefloating
    sleep 0.1 # Small delay to ensure float state changes
    hyprctl dispatch centerwindow
    
    # Set window to 50% of screen size (2/4 width, 2/4 height)
    local monitor_info=$(hyprctl monitors -j | jq '.[0]')
    local width=$(echo "$monitor_info" | jq '.width')
    local height=$(echo "$monitor_info" | jq '.height')
    
    local new_width=$((width / 2))
    local new_height=$((height / 2))
    
    hyprctl dispatch resizeactive exact "$new_width" "$new_height"
    hyprctl dispatch centerwindow
    
    notify_mode "Float Toggle" "Window toggled float/tile with centered positioning"
}

# Recent workspace switch
recent_workspace() {
    hyprctl dispatch workspace previous
}

# Main command dispatcher
case "${1:-}" in
    "focus")
        window_focus "${2:-}"
        ;;
    "resize-mode")
        enter_resize_mode
        ;;
    "resize")
        resize_window "${2:-}" "${3:-$RESIZE_STEP_SMALL}"
        ;;
    "wasd-mode") 
        enter_wasd_mode
        ;;
    "wasd")
        wasd_navigate "${2:-}"
        ;;
    "float-toggle")
        float_toggle
        ;;
    "recent-workspace")
        recent_workspace
        ;;
    *)
        echo "Usage: $0 {focus|resize-mode|resize|wasd-mode|wasd|float-toggle|recent-workspace} [args...]"
        echo "Hyprland modal window management matching skhd behavior exactly"
        exit 1
        ;;
esac
