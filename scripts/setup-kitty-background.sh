#!/usr/bin/env bash
set -euo pipefail

KITTY_CONFIG_DIR="$HOME/.config/kitty"
BACKGROUND_URL="https://images.alphacoders.com/137/1370942.png"
BACKGROUND_FILE="$KITTY_CONFIG_DIR/background.png"

# Create kitty config directory
mkdir -p "$KITTY_CONFIG_DIR"

# Download background image if it doesn't exist
if [ ! -f "$BACKGROUND_FILE" ]; then
    echo "Downloading kitty background image..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$BACKGROUND_FILE" "$BACKGROUND_URL" || {
            echo "Failed to download with wget, trying curl..."
            curl -s -o "$BACKGROUND_FILE" "$BACKGROUND_URL" || {
                echo "Failed to download background image"
                exit 1
            }
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$BACKGROUND_FILE" "$BACKGROUND_URL" || {
            echo "Failed to download background image"
            exit 1
        }
    else
        echo "No download utility available, skipping background"
        exit 1
    fi
    echo "Kitty background downloaded successfully!"
else
    echo "Kitty background already exists: $BACKGROUND_FILE"
fi

echo "Kitty background setup complete!"
