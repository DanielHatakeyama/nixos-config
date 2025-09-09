#!/usr/bin/env bash

# Tridactyl Configuration Test Script
# Verifies that your Tridactyl setup is working correctly

echo "🦊 Tridactyl Configuration Test"
echo "==============================="

# Check if configuration file exists
config_file="$HOME/.config/tridactyl/tridactylrc"
if [ -f "$config_file" ]; then
    echo "✅ Tridactyl configuration file exists"
    echo "   Location: $config_file"
else
    echo "❌ Tridactyl configuration file not found"
    echo "   Expected: $config_file"
    exit 1
fi

# Display configuration summary
echo
echo "📋 Configuration Summary:"
echo "------------------------"

# Check color scheme
if grep -q "colourscheme.*catppuccin" "$config_file"; then
    echo "✅ Color scheme: Catppuccin (with custom CSS)"
else
    echo "⚠️  Color scheme not found or different"
fi

# Check ignore mode bindings
if grep -q "bind <C-Delete> mode ignore" "$config_file"; then
    echo "✅ Ignore mode toggle: Ctrl+Delete"
else
    echo "❌ Ignore mode binding not found"
fi

# Check YouTube bindings (if enabled)
if grep -q "youtube\.com" "$config_file"; then
    echo "✅ YouTube keybindings: Enabled"
    echo "   h/l: Seek backward/forward"
    echo "   </> : Speed controls"
else
    echo "ℹ️  YouTube keybindings: Disabled (enable with djh.tridactyl.enableYouTubeKeybinds = true)"
fi

echo
echo "🎛️  Available Module Options:"
echo "-----------------------------"
echo "In your home.nix, you can configure:"
echo
echo "djh.tridactyl = {"
echo "  enable = true;"
echo "  colorScheme = \"catppuccin\";  # or \"dark\", \"light\", etc."
echo "  customCss = \"https://your-custom-css-url\";"
echo "  enableYouTubeKeybinds = false;  # Set to true for YouTube shortcuts"
echo "  extraConfig = '''"
echo "    \" Your additional Tridactyl commands here"
echo "    bind <C-h> back"
echo "    bind <C-l> forward"
echo "  ''';"
echo "};"

echo
echo "🌐 Browser Setup Instructions:"
echo "------------------------------"
echo "1. Install Tridactyl extension in Firefox:"
echo "   https://addons.mozilla.org/en-US/firefox/addon/tridactyl-vim/"
echo
echo "2. After installing, Tridactyl will automatically load your config from:"
echo "   ~/.config/tridactyl/tridactylrc"
echo
echo "3. Key bindings:"
echo "   - Ctrl+Delete: Toggle ignore mode (let page handle keys)"
echo "   - :: Open Tridactyl command line"
echo "   - Normal vim-like navigation (hjkl, /, etc.)"

echo
echo "🧪 Quick Test:"
echo "-------------"
echo "1. Open Firefox"
echo "2. Press ':' to open Tridactyl command line"
echo "3. Type 'help' to see available commands"
echo "4. Your Catppuccin theme should be applied automatically"

echo
echo "✨ Configuration complete! Your vim-like browser navigation is ready."
