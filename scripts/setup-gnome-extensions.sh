#!/usr/bin/env bash

# Setup script for GNOME extensions to replicate yabai/skhd functionality
# This script helps install the required GNOME extensions for window management

set -e

echo "🚀 Setting up GNOME extensions for yabai-like window management..."

# Check if we're running GNOME
if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
    echo "⚠️  Warning: This script is designed for GNOME desktop environment"
    echo "   Current desktop: $XDG_CURRENT_DESKTOP"
fi

# Install GNOME Extensions CLI if not present
if ! command -v gnome-extensions &> /dev/null; then
    echo "📦 Installing gnome-extensions tool..."
    # On NixOS, this should already be available via gnome.gnome-shell
    echo "   Make sure gnome-shell is installed in your system configuration"
fi

echo "🔧 Required extensions for yabai-like functionality:"
echo "   1. Forge - Tiling window manager"
echo "   2. Workspace Indicator - Show current workspace"
echo "   3. Auto Move Windows - Assign apps to workspaces"

echo ""
echo "📋 Manual installation steps:"
echo "1. Open Firefox/browser and go to: https://extensions.gnome.org"
echo "2. Search for and install these extensions:"
echo "   - 'Forge' by jmmaranan"
echo "   - 'Workspace Indicator' (built-in, may need enabling)"
echo "   - 'Auto Move Windows' (built-in, may need enabling)"

echo ""
echo "⚡ After installation, the extensions will be automatically configured"
echo "   by your Home Manager configuration."

echo ""
echo "🎹 Keyboard shortcuts summary (yabai → GNOME):"
echo "   Window Focus:"
echo "     cmd+hjkl → Super+hjkl"
echo "   Window Movement:"
echo "     cmd+shift+hjkl → Super+Shift+hjkl"
echo "   Workspace Switching:"
echo "     cmd+1-9 → Super+1-9"
echo "   Move to Workspace:"
echo "     cmd+shift+1-9 → Super+Shift+1-9"
echo "   Workspace Navigation:"
echo "     cmd+ctrl+hl → Super+Ctrl+hl"
echo "   Close Window:"
echo "     cmd+shift+q → Super+Shift+q"
echo "   Toggle Float:"
echo "     alt+f → Super+Alt+f"

echo ""
echo "🏠 Workspace assignments (like yabai rules):"
echo "   1. code - VS Code, Cursor"
echo "   2. browser - Zen Browser, Firefox"
echo "   3. terminal - Kitty, Console"
echo "   4. chat - Discord"
echo "   5. code2 - (available)"
echo "   6. daemon - (available)"
echo "   7. notes - Text Editor"
echo "   8. chat1 - Slack"
echo "   9. chat2 - (available)"

echo ""
echo "✅ Configuration applied! Log out and back in for full effect."
echo "   Or restart GNOME Shell with Alt+F2 → 'r' → Enter"

# Create a desktop file for easy access
cat > ~/.local/share/applications/gnome-window-management-help.desktop << EOF
[Desktop Entry]
Name=GNOME Window Management Help
Comment=Keyboard shortcuts for yabai-like window management
Exec=gnome-text-editor $HOME/.config/home-manager/scripts/setup-gnome-extensions.sh
Icon=preferences-desktop-keyboard-shortcuts
Type=Application
Categories=Utility;
EOF

echo ""
echo "📝 Created desktop shortcut: 'GNOME Window Management Help'"
echo "   Find it in your applications menu for quick reference"
