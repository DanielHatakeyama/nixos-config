#!/usr/bin/env bash

# Keyboard Mapping Troubleshooting Script for GNOME/Wayland
# Diagnoses and fixes Caps Lock → Escape mapping issues

echo "⌨️  Keyboard Mapping Diagnostics"
echo "================================"

# Check if we're running Wayland or X11
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo "🌊 Session Type: Wayland"
    wayland_mode=true
else
    echo "🪟 Session Type: X11"
    wayland_mode=false
fi

# Check GNOME keyboard settings
echo
echo "🔍 GNOME Keyboard Settings:"
echo "-------------------------"
xkb_options=$(gsettings get org.gnome.desktop.input-sources xkb-options)
echo "XKB Options: $xkb_options"

if [[ "$xkb_options" == *"caps:escape"* ]]; then
    echo "✅ Caps Lock → Escape mapping is configured"
else
    echo "❌ Caps Lock → Escape mapping is NOT configured"
    echo "   Fixing now..."
    gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:swap_alt_win', 'caps:escape']"
    echo "✅ Fixed! Settings updated."
fi

if [[ "$xkb_options" == *"altwin:swap_alt_win"* ]]; then
    echo "✅ Alt ↔ Super swap is configured"
else
    echo "❌ Alt ↔ Super swap is NOT configured"
fi

# Test the actual key mapping
echo
echo "🧪 Key Mapping Test:"
echo "-------------------"
echo "Please test your Caps Lock key now:"
echo "1. Press Caps Lock - it should act like Escape"
echo "2. If it doesn't work, try the solutions below"

# Provide different solutions based on session type
echo
echo "🛠️  Troubleshooting Solutions:"
echo "-----------------------------"

if [ "$wayland_mode" = true ]; then
    echo "For Wayland session:"
    echo "1. Log out and log back in (settings may need session restart)"
    echo "2. If problem persists, try switching to X11 session temporarily:"
    echo "   - At login screen, click gear icon → select 'GNOME on Xorg'"
    echo "3. Some applications (like Cursor) may ignore GNOME keyboard settings"
else
    echo "For X11 session:"
    echo "1. Apply mapping manually:"
    echo "   setxkbmap -option caps:escape,altwin:swap_alt_win"
    echo "2. Make it permanent by running home-manager switch again"
fi

# Check for problematic applications
echo
echo "📱 Known Application Issues:"
echo "----------------------------"
echo "Some applications don't respect GNOME keyboard settings:"
echo "• Electron apps (VS Code, Cursor, Discord, etc.)"
echo "• Some Java applications"
echo "• VirtualBox VMs"
echo "• Flatpak applications (sandboxed)"

echo
echo "🔧 Additional Fixes:"
echo "------------------"

# Create a manual fix script
cat > /tmp/fix-keyboard.sh << 'EOF'
#!/usr/bin/env bash
# Manual keyboard mapping fix
gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:swap_alt_win', 'caps:escape']"
# For X11 sessions
if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    setxkbmap -option caps:escape,altwin:swap_alt_win
fi
echo "Keyboard mapping applied!"
EOF

chmod +x /tmp/fix-keyboard.sh
echo "Created manual fix script: /tmp/fix-keyboard.sh"
echo "Run this anytime keyboard mapping breaks: /tmp/fix-keyboard.sh"

# Check if the autostart file was created
autostart_file="$HOME/.config/autostart/keyboard-setup.desktop"
if [ -f "$autostart_file" ]; then
    echo "✅ Autostart file exists: $autostart_file"
else
    echo "❌ Autostart file missing - keyboard mapping may not persist"
fi

echo
echo "💡 Pro Tips:"
echo "----------"
echo "1. Use 'gnome-tweaks' → Keyboard → Additional Layout Options"
echo "2. For immediate testing: open terminal and try pressing Caps Lock"
echo "3. In vim/neovim, Caps Lock should work like Escape"
echo "4. If using external keyboard, mapping applies to all keyboards"

echo
echo "🎯 Expected Behavior:"
echo "-------------------"
echo "• Caps Lock key → Escape function"
echo "• Alt key → Super/Cmd function (opens Activities, etc.)"  
echo "• Super key → Alt function (your window management shortcuts)"

echo
echo "If problems persist, GNOME's keyboard handling on Wayland can be finicky."
echo "Consider switching to X11 session for more reliable key remapping."
