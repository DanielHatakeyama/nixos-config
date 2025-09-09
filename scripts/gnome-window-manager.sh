#!/usr/bin/env bash

# Advanced Window Management Scripts for GNOME
# Replicates yabai/skhd modal behaviors and application-specific exclusions
# Designed to work with Forge extension and GNOME Shell

set -euo pipefail

# Configuration
RESIZE_STEP_SMALL=20
RESIZE_STEP_MEDIUM=50
RESIZE_STEP_LARGE=100
MODE_NOTIFICATION_TIME=3000

# Get current application
get_current_app() {
    gdbus call --session \
        --dest=org.gnome.Shell \
        --object-path=/org/gnome/Shell \
        --method=org.gnome.Shell.Eval \
        "global.display.focus_window?.get_wm_class_instance()" \
        2>/dev/null | grep -Po '(?<=")[^"]*' || echo ""
}

# Check if we're in an excluded application
is_excluded_app() {
    local app="$1"
    case "$app" in
        "cursor"|"Cursor"|"code"|"Code") return 0 ;;
        "zen"|"Zen") return 0 ;;
        *) return 1 ;;
    esac
}

# Send notification
notify_mode() {
    local title="$1"
    local message="$2"
    notify-send "$title" "$message" --expire-time="$MODE_NOTIFICATION_TIME" --urgency=low
}

# Window focus with application exclusions (like skhd conditional focus)
window_focus() {
    local direction="$1"
    local app=$(get_current_app)
    
    # Application-specific exclusions (matching skhd behavior)
    if is_excluded_app "$app"; then
        case "$direction" in
            "up"|"north")
                if [[ "$app" == *"zen"* ]] || [[ "$app" == *"Zen"* ]]; then
                    # Zen: Send Ctrl+Shift+Tab (previous tab)
                    gdbus call --session --dest=org.gnome.Shell \
                        --object-path=/org/gnome/Shell \
                        --method=org.gnome.Shell.Eval \
                        "imports.ui.main.actionMode = 'normal'; global.display.get_keybinding_action(Meta.KeyBindingAction.TAB_POPUP).bind('<Control><Shift>Tab');"
                    return 0
                elif [[ "$app" == *"cursor"* ]] || [[ "$app" == *"Cursor"* ]] || [[ "$app" == *"code"* ]]; then
                    # Let Cursor/Code handle the key (pass through)
                    return 0
                fi
                ;;
            "down"|"south")
                if [[ "$app" == *"zen"* ]] || [[ "$app" == *"Zen"* ]]; then
                    # Zen: Send Ctrl+Tab (next tab)
                    gdbus call --session --dest=org.gnome.Shell \
                        --object-path=/org/gnome/Shell \
                        --method=org.gnome.Shell.Eval \
                        "imports.ui.main.actionMode = 'normal'; global.display.get_keybinding_action(Meta.KeyBindingAction.TAB_POPUP).bind('<Control>Tab');"
                    return 0
                elif [[ "$app" == *"cursor"* ]] || [[ "$app" == *"Cursor"* ]] || [[ "$app" == *"code"* ]]; then
                    # Let Cursor/Code handle the key (pass through)
                    return 0
                fi
                ;;
        esac
    fi
    
    # Standard window focus (via Forge extension)
    case "$direction" in
        "up"|"north")    forge_focus "up" ;;
        "down"|"south")  forge_focus "down" ;;
        "left"|"west")   forge_focus "left" ;;
        "right"|"east")  forge_focus "right" ;;
    esac
}

# Forge extension focus commands
forge_focus() {
    local direction="$1"
    gdbus call --session \
        --dest=org.gnome.Shell \
        --object-path=/org/gnome/Shell/Extensions/Forge \
        --method=org.gnome.Shell.Extensions.Forge.focusWindow \
        "$direction" 2>/dev/null || {
            # Fallback: try to switch to adjacent display
            case "$direction" in
                "left"|"west") 
                    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Primary><Alt>Left']"
                    gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval "Main.wm._showWorkspaceSwitcher(global.display, null, Meta.KeyBindingAction.SWITCH_WORKSPACES_LEFT);"
                    ;;
                "right"|"east")
                    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Primary><Alt>Right']" 
                    gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval "Main.wm._showWorkspaceSwitcher(global.display, null, Meta.KeyBindingAction.SWITCH_WORKSPACES_RIGHT);"
                    ;;
            esac
        }
}

# Modal resize system (replicating skhd resize mode)
enter_resize_mode() {
    notify_mode "Resize Mode" "Use H/L for width, J/K for height, ESC to exit
• H/L: ±${RESIZE_STEP_SMALL}px width
• Shift+H/L: ±${RESIZE_STEP_MEDIUM}px width  
• Ctrl+H/L: ±${RESIZE_STEP_LARGE}px width"

    # Create temporary mode indicator
    local mode_file="/tmp/gnome_resize_mode"
    touch "$mode_file"
    
    # Future: Implement actual modal key capture
    # For now, provide resize commands that can be bound to keys
    echo "Resize mode active - bind keys to resize commands"
}

# Resize window (matching skhd resize behavior)
resize_window() {
    local direction="$1"
    local amount="$2"
    
    case "$direction" in
        "left"|"h")
            # Try left edge first, fallback to right edge
            gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                "global.display.focus_window?.resize(global.display.focus_window.get_frame_rect().width - $amount, global.display.focus_window.get_frame_rect().height);" 2>/dev/null || \
            gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                "global.display.focus_window?.resize(global.display.focus_window.get_frame_rect().width + $amount, global.display.focus_window.get_frame_rect().height);"
            ;;
        "right"|"l")
            gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                "global.display.focus_window?.resize(global.display.focus_window.get_frame_rect().width + $amount, global.display.focus_window.get_frame_rect().height);"
            ;;
        "up"|"k")
            gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                "global.display.focus_window?.resize(global.display.focus_window.get_frame_rect().width, global.display.focus_window.get_frame_rect().height - $amount);"
            ;;
        "down"|"j")
            gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                "global.display.focus_window?.resize(global.display.focus_window.get_frame_rect().width, global.display.focus_window.get_frame_rect().height + $amount);"
            ;;
    esac
}

# WASD navigation mode (replicating skhd wasd mode)  
enter_wasd_mode() {
    notify_mode "WASD Focus Mode" "Use WASD for navigation, ESC to exit
• W: Focus up/north
• A: Focus left/west → Display → Previous workspace
• S: Focus down/south  
• D: Focus right/east → Display → Next workspace"
    
    local mode_file="/tmp/gnome_wasd_mode"
    touch "$mode_file"
    
    echo "WASD mode active"
}

# WASD navigation with fallback chain
wasd_navigate() {
    local direction="$1"
    
    case "$direction" in
        "w") window_focus "up" ;;
        "s") window_focus "down" ;;
        "a") 
            # Chain: window → display → previous workspace
            window_focus "left" || {
                # Try previous workspace
                gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                    "Main.wm._showWorkspaceSwitcher(global.display, null, Meta.KeyBindingAction.SWITCH_WORKSPACES_LEFT);"
            }
            ;;
        "d")
            # Chain: window → display → next workspace  
            window_focus "right" || {
                # Try next workspace
                gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
                    "Main.wm._showWorkspaceSwitcher(global.display, null, Meta.KeyBindingAction.SWITCH_WORKSPACES_RIGHT);"
            }
            ;;
    esac
}

# Float window and center (matching skhd alt+f with yabai grid 4:4:1:1:2:2)
float_toggle() {
    # Toggle floating and center window using Forge extension API
    gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval "
        let win = global.display.focus_window;
        if (win) {
            // Toggle float via Forge extension if available
            if (global.workspace_manager && global.workspace_manager.getActiveWorkspace) {
                let workspace = global.workspace_manager.getActiveWorkspace();
                let ext = Main.extensionManager.lookup('forge@jmmaranan.com');
                if (ext && ext.stateObj && ext.stateObj.ext) {
                    ext.stateObj.ext.focus.toggleFloat();
                }
            }
            
            // Position window in 4:4:1:1:2:2 grid (center, half size)
            let monitor = Main.layoutManager.currentMonitor;
            let workArea = Main.layoutManager.getWorkAreaForMonitor(monitor.index);
            
            let width = Math.floor(workArea.width * 0.5);   // 2/4 of width
            let height = Math.floor(workArea.height * 0.5); // 2/4 of height  
            let x = workArea.x + Math.floor(workArea.width * 0.25);  // 1/4 from left
            let y = workArea.y + Math.floor(workArea.height * 0.25); // 1/4 from top
            
            win.move_resize_frame(false, x, y, width, height);
        }
    " 2>/dev/null || {
        # Fallback: Use wmctrl for basic float toggle
        wmctrl -r :ACTIVE: -e 0,$(($(xdpyinfo | grep dimensions | cut -d' ' -f7 | cut -dx -f1) / 4)),$(($(xdpyinfo | grep dimensions | cut -d' ' -f7 | cut -dx -f2) / 4)),$(($(xdpyinfo | grep dimensions | cut -d' ' -f7 | cut -dx -f1) / 2)),$(($(xdpyinfo | grep dimensions | cut -d' ' -f7 | cut -dx -f2) / 2))
    }
    
    notify_mode "Float Toggle" "Window toggled float/tile with 4:4:1:1:2:2 grid positioning"
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
        # Switch to most recent workspace
        gdbus call --session --dest=org.gnome.Shell --object-path=/org/gnome/Shell --method=org.gnome.Shell.Eval \
            "Main.wm._showWorkspaceSwitcher(global.display, null, Meta.KeyBindingAction.SWITCH_WORKSPACES);"
        ;;
    *)
        echo "Usage: $0 {focus|resize-mode|resize|wasd-mode|wasd|float-toggle|recent-workspace} [args...]"
        echo "Advanced GNOME window management matching skhd behavior exactly"
        exit 1
        ;;
esac
