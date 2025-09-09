#!/usr/bin/env bash

# Enhanced Window Management Test Script
# Tests the comprehensive GNOME + Forge configuration with modal systems

echo "🚀 Testing Enhanced GNOME Window Management System"
echo "================================================="

# Test 1: Check if Forge extension is enabled
echo "1. Checking Forge extension status..."
forge_enabled=$(dconf read /org/gnome/shell/enabled-extensions | grep -c "forge")
if [ "$forge_enabled" -gt 0 ]; then
    echo "   ✅ Forge extension is enabled"
else
    echo "   ❌ Forge extension not found in enabled extensions"
    echo "   📝 Note: Extension may need manual installation via GNOME Extensions"
fi

# Test 2: Verify Forge BSP tiling configuration
echo
echo "2. Checking Forge BSP tiling configuration..."
bsp_layout=$(dconf read /org/gnome/shell/extensions/forge/window-default-layout)
gap_size=$(dconf read /org/gnome/shell/extensions/forge/window-gap-size)
opacity=$(dconf read /org/gnome/shell/extensions/forge/window-default-opacity)

echo "   Layout: $bsp_layout (should be 'bsp')"
echo "   Gap size: $gap_size (should be 6)"
echo "   Default opacity: $opacity (should be 0.95)"

# Test 3: Check custom keybindings
echo
echo "3. Testing custom keybindings..."
modal_resize=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/modal-resize/ command)
wasd_mode=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/wasd-mode/ command)

echo "   Modal resize: $modal_resize"
echo "   WASD mode: $wasd_mode"

# Test 4: Check if our window management script is executable
echo
echo "4. Checking window management script..."
script_path="/home/djh/.config/home-manager/scripts/gnome-window-manager.sh"
if [ -x "$script_path" ]; then
    echo "   ✅ Window management script is executable"
    echo "   📄 Script size: $(wc -l < "$script_path") lines"
else
    echo "   ❌ Window management script not found or not executable"
fi

# Test 5: Verify workspace keybindings
echo
echo "5. Testing workspace keybindings..."
for i in {1..9}; do
    switch_key=$(gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-$i)
    move_key=$(gsettings get org.gnome.desktop.wm.keybindings move-to-workspace-$i)
    echo "   Workspace $i: Switch=$switch_key, Move=$move_key"
done

# Test 6: Check Mutter experimental features
echo
echo "6. Checking Mutter experimental features..."
experimental=$(gsettings get org.gnome.mutter experimental-features)
focus_mode=$(gsettings get org.gnome.desktop.wm.preferences focus-mode)
echo "   Experimental features: $experimental"
echo "   Focus mode: $focus_mode (should be 'sloppy' for better tiling)"

# Test 7: Instructions for manual testing
echo
echo "🧪 Manual Testing Instructions:"
echo "==============================="
echo "1. Open multiple windows (try Alt+Return for new terminal)"
echo "2. Test workspace switching: Alt+1, Alt+2, etc."
echo "3. Test window moving: Alt+Shift+1, Alt+Shift+2, etc."
echo "4. Test directional focus: Alt+h, Alt+j, Alt+k, Alt+l"
echo "5. Test modal resize: Alt+p (should show notification), then H/L/J/K"
echo "6. Test WASD mode: Alt+w (should show notification), then W/A/S/D"
echo "7. Test float toggle: Alt+f (should use 4:4:1:1:2:2 grid)"

echo
echo "🎯 Success Criteria:"
echo "===================="
echo "- Windows should tile automatically in BSP layout"
echo "- Keyboard navigation should change focus between windows"
echo "- Modal systems should provide visual feedback via notifications"
echo "- Float toggle should position windows in center of screen"

echo
echo "📝 If tiling doesn't work:"
echo "========================="
echo "1. Install Forge extension manually: https://extensions.gnome.org/extension/4481/forge/"
echo "2. Enable it in GNOME Extensions app"
echo "3. Rerun: home-manager switch"
echo "4. Log out and log back in"

echo
echo "✨ Configuration complete! Test the keyboard shortcuts above."
