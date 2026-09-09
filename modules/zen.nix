# Zen Browser - configuration and keybind helpers
# The zen-browser package itself is provided by the flake input:
#   zen-browser.homeModules.twilight (imported in flake.nix)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.djh.zen;
in
{
  options.djh.zen = {
    enable = mkEnableOption "Zen Browser configuration and keybind helpers";

    setAsDefaultBrowser = mkOption {
      type = types.bool;
      default = false;
      description = "Set Zen as the default web browser";
    };
  };

  config = mkIf cfg.enable {
    # Helper script to apply custom keybindings to Zen Browser profile
    home.packages = [
      (pkgs.writeShellScriptBin "zen-apply-keybind" ''
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

        cp "$SHORTCUTS_FILE" "''${SHORTCUTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

        ${pkgs.jq}/bin/jq '. + {"zen-compact-mode-toggle": {"key": "m", "modifiers": {"control": false, "alt": true, "shift": false, "meta": false, "accel": true}}}' \
          "$SHORTCUTS_FILE" > "$SHORTCUTS_FILE.tmp" && mv "$SHORTCUTS_FILE.tmp" "$SHORTCUTS_FILE"

        echo "Applied Alt+Ctrl+M for compact mode toggle"
        echo "Restart Zen Browser to apply the new keybind"
      '')
    ];

    xdg.mimeApps = mkIf cfg.setAsDefaultBrowser {
      enable = true;
      defaultApplications = {
        "text/html" = "zen-browser.desktop";
        "x-scheme-handler/http" = "zen-browser.desktop";
        "x-scheme-handler/https" = "zen-browser.desktop";
        "x-scheme-handler/about" = "zen-browser.desktop";
        "x-scheme-handler/unknown" = "zen-browser.desktop";
      };
    };
  };
}
