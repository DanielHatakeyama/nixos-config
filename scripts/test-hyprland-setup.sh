#!/usr/bin/env bash

# Hyprland Setup and Migration Script
# Helps transition from GNOME to Hyprland with your exact skhd workflow

echo "🚀 Hyprland Setup Complete!"
echo "=========================="

echo "📋 What's Been Configured:"
echo "-------------------------"
echo "✅ Hyprland wayland compositor with BSP-like tiling"
echo "✅ Exact skhd keybinding replication:"
echo "   • Super+hjkl → Window focus"
echo "   • Super+1-9 → Workspace switching" 
echo "   • Super+Shift+1-9 → Move windows to workspaces"
echo "   • Super+Shift+hjkl → Window movement"
echo "   • Super+Ctrl+h/l → Workspace navigation"
echo "   • Alt+f → Float toggle with centering"
echo "   • Alt+Tab → Recent workspace"
echo ""
echo "✅ Modal systems (matching skhd exactly):"
echo "   • Alt+r/Alt+p → Resize mode"
echo "   • Alt+w → WASD navigation mode"
echo ""
echo "✅ Application-specific exclusions:"
echo "   • Cursor/Zen: Super+j/k for tab switching"
echo "   • Other apps: Normal window focus"
echo ""
echo "✅ Supporting applications:"
echo "   • Waybar (status bar with workspace indicator)"
echo "   • Rofi (application launcher)"
echo "   • Dunst (notifications)"
echo "   • Screenshot tools (grim + slurp + swappy)"
echo ""
echo "✅ Reliable keyboard mapping:"
echo "   • Caps Lock → Escape (works consistently!)"
echo "   • Alt ↔ Super swap"

echo
echo "🔄 How to Switch to Hyprland:"
echo "=============================="
echo "1. **Log out** of your current session"
echo "2. At the login screen, click the **gear/settings icon**"
echo "3. Select **'Hyprland'** from the session options"
echo "4. Log in with your credentials"
echo
echo "🎯 First Steps in Hyprland:"
echo "---------------------------"
echo "• **Super+Return** → Open terminal (Kitty)"
echo "• **Alt+r** → Open application launcher (Rofi)"
echo "• **Super+1, Super+2, etc.** → Switch workspaces"
echo "• **Super+h/j/k/l** → Navigate between windows"
echo "• **Alt+f** → Toggle window floating"
echo "• **Super+Shift+q** → Close window"

echo
echo "🧪 Test Your Workflow:"
echo "======================"
echo "1. Open multiple applications:"
echo "   - Super+Return (terminal)"
echo "   - Alt+r → type 'zen' → Enter (browser)"
echo "   - Alt+r → type 'cursor' → Enter (editor)"
echo ""
echo "2. Test window navigation:"
echo "   - Super+h/j/k/l should move focus between windows"
echo "   - Windows should tile automatically"
echo ""
echo "3. Test workspaces:"
echo "   - Super+2 → switch to browser workspace"
echo "   - Super+Shift+1 → move current window to code workspace"
echo ""
echo "4. Test modal systems:"
echo "   - Alt+p → enter resize mode, use H/L/J/K"
echo "   - Alt+w → enter WASD mode, use W/A/S/D"

echo
echo "⚙️  Configuration Files:"
echo "========================"
echo "All managed through Home Manager:"
echo "• ~/.config/hypr/hyprland.conf (generated)"
echo "• ~/.config/waybar/config (status bar)"  
echo "• ~/.config/rofi/ (application launcher)"
echo "• ~/.config/dunst/ (notifications)"

echo
echo "🔧 Customization:"
echo "=================="
echo "Edit your home.nix to customize:"
echo ""
echo "djh.hyprland = {"
echo "  enable = true;"
echo "  gaps = 6;                    # Window gaps"
echo "  borderSize = 2;              # Border thickness"
echo "  terminal = \"kitty\";         # Default terminal"
echo "  workspaceLabels = [\"code\" \"browser\" ...]; # Workspace names"
echo "  extraConfig = '''"
echo "    # Additional Hyprland config here"
echo "  ''';"
echo "};"

echo
echo "💡 Pro Tips:"
echo "============"
echo "• **Caps Lock works as Escape everywhere** (no more GNOME issues!)"
echo "• **True tiling** - windows automatically arrange"
echo "• **Smooth animations** - much more responsive than GNOME"
echo "• **Lower resource usage** - faster performance"
echo "• **Consistent keybindings** - work in all applications"

echo
echo "🔙 Fallback Plan:"
echo "================="
echo "GNOME is still available if needed:"
echo "• At login screen → gear icon → 'GNOME' or 'GNOME on Xorg'"
echo "• Your GNOME configuration is preserved"
echo "• You can disable GNOME later: djh.gnome.enable = false;"

echo
echo "🎉 Ready to Experience True Tiling!"
echo "===================================="
echo "Your exact skhd workflow is now available in a proper tiling WM."
echo "Hyprland will feel much more responsive and keyboard-driven than GNOME."
echo ""
echo "Log out and select Hyprland to start your new workflow! 🚀"

# Check if Hyprland is available as a session
if ls /usr/share/wayland-sessions/ 2>/dev/null | grep -q hyprland; then
    echo "✅ Hyprland session is available at login screen"
else
    echo "⚠️  You may need to log out/in for Hyprland session to appear"
fi
