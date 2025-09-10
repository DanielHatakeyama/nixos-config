#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
WALLPAPER_URL="https://wallpapercave.com/wp/wp13346656.png"
WALLPAPER_FILE="$WALLPAPER_DIR/landscape.png"
HYPRPAPER_CONFIG="$HOME/.config/hypr/hyprpaper.conf"

# Create wallpaper directory
mkdir -p "$WALLPAPER_DIR"

# Download wallpaper if it doesn't exist
if [ ! -f "$WALLPAPER_FILE" ]; then
    echo "Downloading new wallpaper..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$WALLPAPER_FILE" "$WALLPAPER_URL" || {
            echo "Failed to download with wget, trying curl..."
            curl -s -o "$WALLPAPER_FILE" "$WALLPAPER_URL" || {
                echo "Failed to download wallpaper, using solid color fallback"
                exit 0
            }
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$WALLPAPER_FILE" "$WALLPAPER_URL" || {
            echo "Failed to download wallpaper, using solid color fallback"
            exit 0
        }
    else
        echo "No download utility available, skipping wallpaper"
        exit 0
    fi
    echo "Wallpaper downloaded successfully!"
fi

# Create hyprpaper configuration
cat > "$HYPRPAPER_CONFIG" << EOF
preload = $WALLPAPER_FILE
wallpaper = ,$WALLPAPER_FILE

# Disable splash text
splash = false
ipc = on
EOF

# Kill any existing hyprpaper instances and start new one
pkill hyprpaper 2>/dev/null || true
sleep 0.5
hyprpaper &

echo "Wallpaper setup complete!"
