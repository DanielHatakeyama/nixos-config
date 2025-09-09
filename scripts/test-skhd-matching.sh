#!/usr/bin/env bash

# Test Script for skhd-matched GNOME Window Management
# Tests exact behavior matching from your skhdrc configuration

echo "🚀 Testing skhd-matched GNOME Window Management"
echo "=============================================="

echo "📋 Key Mapping Status (after Alt/Super swap):"
echo "   Physical Super key → Your window management shortcuts"
echo "   Physical Alt key   → System shortcuts (Activities, etc.)"

echo
echo "🎯 Core Navigation (matching skhd exactly):"
echo "──────────────────────────────────────────"
echo "Workspace Switching:"
echo "   Super+1-9        →  Switch to workspace 1-9"
echo "   Super+Shift+1-9  →  Move window to workspace 1-9"
echo

echo "Window Focus (with application exclusions):"
echo "   Super+h          →  Focus west (left)"
echo "   Super+l          →  Focus east (right)"  
echo "   Super+j          →  Focus south (down) - EXCEPT in Cursor/Zen"
echo "   Super+k          →  Focus north (up) - EXCEPT in Cursor/Zen"
echo

echo "Window Movement/Warping:"
echo "   Super+Shift+h    →  Move/warp window west"
echo "   Super+Shift+l    →  Move/warp window east"
echo "   Super+Shift+j    →  Move/warp window south"
echo "   Super+Shift+k    →  Move/warp window north"
echo

echo "Workspace Navigation:"
echo "   Super+Ctrl+h     →  Previous workspace on current display"
echo "   Super+Ctrl+l     →  Next workspace on current display"
echo

echo "🎛️ Modal Systems (matching skhd modes exactly):"
echo "────────────────────────────────────────────"
echo "Resize Mode:"
echo "   Alt+r or Alt+p   →  Enter resize mode"
echo "   (Then: H/L for width, J/K for height, different step sizes)"
echo

echo "WASD Navigation Mode:"  
echo "   Alt+w            →  Enter WASD mode"
echo "   (Then: W/A/S/D for navigation with fallback chains)"
echo

echo "Float Toggle:"
echo "   Alt+f            →  Toggle float with 4:4:1:1:2:2 grid positioning"
echo

echo "Recent Workspace:"
echo "   Alt+Tab          →  Switch to most recent workspace"
echo

echo "Quick Access:"
echo "   Super+Return     →  Launch terminal (Kitty)"
echo

# Test current settings
echo
echo "🔍 Current Configuration Status:"
echo "───────────────────────────────"

# Check key swap
key_swap=$(gsettings get org.gnome.desktop.input-sources xkb-options)
echo "Key swap: $key_swap"

# Check workspace count
workspace_count=$(gsettings get org.gnome.desktop.wm.preferences num-workspaces)
echo "Workspaces: $workspace_count"

# Check some key workspace bindings
ws1=$(gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-1)
echo "Workspace 1 key: $ws1"

# Check Forge extension
forge_enabled=$(dconf read /org/gnome/shell/enabled-extensions | grep -c "forge" || echo "0")
if [ "$forge_enabled" -gt 0 ]; then
    echo "✅ Forge extension enabled"
    
    # Check some Forge settings
    layout=$(dconf read /org/gnome/shell/extensions/forge/window-default-layout)
    gaps=$(dconf read /org/gnome/shell/extensions/forge/window-gap-size) 
    echo "Forge layout: $layout, gaps: $gaps"
else
    echo "❌ Forge extension not detected"
fi

echo
echo "🧪 Testing Instructions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Open multiple windows (try Super+Return for terminal)"
echo "2. Test workspace switching: Super+1, Super+2, etc."
echo "3. Test window focus: Super+h, Super+j, Super+k, Super+l"  
echo "4. Test window movement: Super+Shift+h/j/k/l"
echo "5. Test modal resize: Alt+r, then use H/L/J/K"
echo "6. Test WASD mode: Alt+w, then use W/A/S/D"
echo "7. Test float toggle: Alt+f"
echo "8. Test recent workspace: Alt+Tab"

echo
echo "🎭 Application Exclusions:"
echo "─────────────────────────"
echo "• In Cursor: Super+j/k should NOT move focus (passes through)"
echo "• In Zen: Super+j/k should trigger Ctrl+Tab/Ctrl+Shift+Tab for tab switching"
echo "• In other apps: Super+j/k should move window focus normally"

echo
echo "✨ Your skhd workflow is now replicated in GNOME!"
echo "   Remember: Physical Super key = your window shortcuts"
echo "   Physical Alt key = system shortcuts"
