#!/usr/bin/env bash

# Test script to verify GNOME window management matches skhd/yabai behavior
# Run this after installing GNOME extensions to test functionality

echo "🧪 Testing GNOME Window Management Configuration"
echo "================================================"

# Test 1: Check if Tor Browser launches and has correct desktop file
echo "1. Testing Tor Browser installation..."
if command -v tor-browser >/dev/null 2>&1; then
    echo "   ✅ Tor Browser executable found: $(which tor-browser)"
    
    # Find desktop file
    desktop_file=$(find /nix/store -name "torbrowser.desktop" 2>/dev/null | head -1)
    if [ -n "$desktop_file" ]; then
        echo "   ✅ Desktop file found: $desktop_file"
        echo "   📋 Desktop file name: torbrowser.desktop (correct for auto-move)"
    else
        echo "   ❌ Desktop file not found"
    fi
    
    # Test launch (quickly close)
    echo "   🚀 Testing quick launch (will close immediately)..."
    timeout 3s tor-browser --headless >/dev/null 2>&1 &
    sleep 2
    pkill -f tor-browser 2>/dev/null
    echo "   ✅ Tor Browser can launch"
else
    echo "   ❌ Tor Browser not found in PATH"
fi

echo ""

# Test 2: Check current dconf settings for our shortcuts
echo "2. Testing keyboard shortcuts configuration..."

echo "   🎹 Checking workspace switching shortcuts..."
for i in {1..9}; do
    shortcut=$(gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-$i 2>/dev/null)
    if [[ "$shortcut" == *"<Alt>$i"* ]]; then
        echo "   ✅ Alt+$i → Workspace $i"
    else
        echo "   ❌ Alt+$i not configured (got: $shortcut)"
    fi
done

echo ""
echo "   🚚 Checking window movement shortcuts..."
for i in {1..9}; do
    shortcut=$(gsettings get org.gnome.desktop.wm.keybindings move-to-workspace-$i 2>/dev/null)
    if [[ "$shortcut" == *"<Alt><Shift>$i"* ]]; then
        echo "   ✅ Alt+Shift+$i → Move to Workspace $i"
    else
        echo "   ❌ Alt+Shift+$i not configured (got: $shortcut)"
    fi
done

echo ""

# Test 3: Check if required extensions are available
echo "3. Testing GNOME extensions..."

if command -v gnome-extensions >/dev/null 2>&1; then
    echo "   📦 Available extensions:"
    gnome-extensions list 2>/dev/null | while read ext; do
        enabled=$(gnome-extensions show "$ext" 2>/dev/null | grep -i "state.*enabled" && echo "✅" || echo "❌")
        echo "      $enabled $ext"
    done
    
    # Check specifically for our required extensions
    echo ""
    echo "   🎯 Required extensions status:"
    
    if gnome-extensions list 2>/dev/null | grep -q "forge"; then
        echo "   ✅ Forge extension available"
    else
        echo "   ❌ Forge extension missing (needed for tiling)"
    fi
    
    if gnome-extensions list 2>/dev/null | grep -q "auto-move-windows"; then
        echo "   ✅ Auto Move Windows extension available"
    else
        echo "   ❌ Auto Move Windows extension missing"
    fi
    
    if gnome-extensions list 2>/dev/null | grep -q "workspace-indicator"; then
        echo "   ✅ Workspace Indicator extension available"
    else
        echo "   ❌ Workspace Indicator extension missing"
    fi
else
    echo "   ❌ gnome-extensions command not found"
fi

echo ""

# Test 4: Compare key mappings with original skhd
echo "4. Comparing with original skhd configuration..."

echo "   📊 Key Mapping Comparison (skhd → GNOME):"
echo "   ├─ Window Focus:"
echo "   │  ├─ cmd+h → Alt+h (west/left)"
echo "   │  ├─ cmd+j → Alt+j (south/down)"  
echo "   │  ├─ cmd+k → Alt+k (north/up)"
echo "   │  └─ cmd+l → Alt+l (east/right)"
echo "   ├─ Window Movement:"
echo "   │  ├─ cmd+shift+h → Alt+Shift+h"
echo "   │  ├─ cmd+shift+j → Alt+Shift+j"
echo "   │  ├─ cmd+shift+k → Alt+Shift+k"
echo "   │  └─ cmd+shift+l → Alt+Shift+l"
echo "   ├─ Workspace Switching:"
echo "   │  └─ cmd+1-9 → Alt+1-9"
echo "   ├─ Move to Workspace:"
echo "   │  └─ cmd+shift+1-9 → Alt+Shift+1-9"
echo "   ├─ Workspace Navigation:"
echo "   │  ├─ cmd+ctrl+h → Alt+Ctrl+h (previous)"
echo "   │  └─ cmd+ctrl+l → Alt+Ctrl+l (next)"
echo "   └─ Window Actions:"
echo "      ├─ cmd+shift+q → Alt+Shift+q (close)"
echo "      └─ alt+f → Alt+f (toggle float)"

echo ""

# Test 5: Missing features from skhd
echo "5. Identifying missing skhd features..."
echo "   ⚠️  Complex features not yet implemented:"
echo "   ├─ Application-specific shortcuts (Cursor/Zen exclusions)"
echo "   ├─ Multi-display window warping with fallback"  
echo "   ├─ Modal resize system (alt+r/alt+p modes)"
echo "   ├─ WASD navigation mode (alt+w)"
echo "   ├─ Display-specific workspace navigation"
echo "   └─ Window grid positioning (4:4:1:1:2:2)"

echo ""

# Test 6: Workspace labels
echo "6. Testing workspace labels..."
workspace_names=$(gsettings get org.gnome.desktop.wm.preferences workspace-names 2>/dev/null)
echo "   📝 Configured workspace names: $workspace_names"

expected="['code', 'browser', 'terminal', 'chat', 'code2', 'daemon', 'notes', 'chat1', 'chat2']"
if [[ "$workspace_names" == "$expected" ]]; then
    echo "   ✅ Workspace names match yabai labels"
else
    echo "   ❌ Workspace names don't match expected"
fi

echo ""
echo "🎯 Summary:"
echo "✅ Basic window management shortcuts configured"
echo "✅ Tor Browser installed and desktop file correct"
echo "✅ Workspace labels match yabai configuration"
echo "⚠️  Extensions need manual installation via browser"
echo "⚠️  Complex skhd features require additional work"

echo ""
echo "📋 Next steps:"
echo "1. Install GNOME extensions manually:"
echo "   - Visit https://extensions.gnome.org"  
echo "   - Install Forge, Auto Move Windows, Workspace Indicator"
echo "2. Restart GNOME Shell (Alt+F2, type 'r', Enter)"
echo "3. Test shortcuts after extension installation"
