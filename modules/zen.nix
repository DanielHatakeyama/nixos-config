# Zen Browser with custom keybinding management
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.djh.zen;

in
{
  options.djh.zen = {
    enable = mkEnableOption "Zen Browser keybind management";
  };

  config = mkIf cfg.enable {
    # Simple script to apply the Alt+Ctrl+M keybind for compact mode
    home.packages = [ 
      (pkgs.writeShellScriptBin "zen-apply-keybind" ''
        #!/bin/bash
        
        # Find the Zen profile directory
        PROFILE_DIR=$(find "$HOME/.zen" -name "*.Default Profile" -type d | head -n 1)
        if [ -z "$PROFILE_DIR" ]; then
            echo "Could not find Zen Browser profile directory"
            exit 1
        fi
        
        SHORTCUTS_FILE="$PROFILE_DIR/zen-keyboard-shortcuts.json"
        if [ ! -f "$SHORTCUTS_FILE" ]; then
            echo "Shortcuts file not found. Please open Zen Browser settings first."
            exit 1
        fi
        
        # Create backup
        cp "$SHORTCUTS_FILE" "''${SHORTCUTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Apply the Alt+Ctrl+M keybind for compact mode
        ${pkgs.jq}/bin/jq '. + {"zen-compact-mode-toggle": {"key": "m", "modifiers": {"control": false, "alt": true, "shift": false, "meta": false, "accel": true}}}' "$SHORTCUTS_FILE" > "$SHORTCUTS_FILE.tmp" && mv "$SHORTCUTS_FILE.tmp" "$SHORTCUTS_FILE"
        
        echo "✓ Applied Alt+Ctrl+M for compact mode toggle"
        echo "Restart Zen Browser to use the new keybind"
      '')
    ];
  };
}
