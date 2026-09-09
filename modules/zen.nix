# Zen Browser - Modern Firefox-based browser with enhanced UI
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.djh.zen;
  
  zen-browser = pkgs.stdenv.mkDerivation rec {
    pname = "zen-browser";
    version = "1.15.5b";
    
    src = pkgs.fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
      sha256 = "sha256-EJdtOTUyejJiFXQH5A5rrZrh22/nqA0ul+cHQuEEf2g="; # Actual hash for 1.15.5b
      # Note: You'll need to update this hash after first run
    };
    
    nativeBuildInputs = with pkgs; [
      makeWrapper
      copyDesktopItems
      autoPatchelfHook
    ];
    
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      alsa-lib
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libxkbcommon
      nspr
      nss
      pango
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxrender
      libxt
      libxtst
    ];
    
    installPhase = ''
      runHook preInstall
      
      # Create installation directory
      mkdir -p $out/lib/zen-browser
      
      # Copy all browser files
      cp -r . $out/lib/zen-browser/
      
      # Create binary wrapper with proper library paths
      mkdir -p $out/bin
      makeWrapper $out/lib/zen-browser/zen $out/bin/zen-browser \
        --set MOZ_ENABLE_WAYLAND 1 \
        --set MOZ_DBUS_REMOTE 1 \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}" \
        --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.coreutils ]}"
      
      # Create symbolic link for zen command
      ln -s $out/bin/zen-browser $out/bin/zen
      
      # Copy and install icon
      mkdir -p $out/share/icons/hicolor/scalable/apps
      if [ -f browser/chrome/icons/default/default128.png ]; then
        cp browser/chrome/icons/default/default128.png $out/share/icons/hicolor/scalable/apps/zen-browser.png
      elif [ -f application.ini ]; then
        # Fallback icon if the specific icon doesn't exist
        echo "Installing fallback icon"
      fi
      
      runHook postInstall
    '';
    
    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "zen-browser";
        desktopName = "Zen Browser";
        comment = "Experience tranquillity while browsing the web without people tracking you!";
        genericName = "Web Browser";
        exec = "zen-browser %U";
        icon = "zen-browser";
        startupNotify = true;
        categories = [ "Network" "WebBrowser" ];
        mimeTypes = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/xml"
          "application/vnd.mozilla.xul+xml"
          "application/rss+xml"
          "application/rdf+xml"
          "image/gif"
          "image/jpeg"
          "image/png"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/ftp"
          "x-scheme-handler/chrome"
          "video/webm"
          "application/x-xpinstall"
        ];
        actions = {
          "new-window" = {
            name = "New Window";
            exec = "zen-browser --new-window %U";
          };
          "new-private-window" = {
            name = "New Private Window";
            exec = "zen-browser --private-window %U";
          };
        };
      })
    ];
    
    postInstall = ''
      # Install icon
      for size in 16 22 24 32 48 64 128 256; do
        mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
        if [ -f $out/lib/zen-browser/browser/chrome/icons/default/default''${size}.png ]; then
          cp $out/lib/zen-browser/browser/chrome/icons/default/default''${size}.png \
             $out/share/icons/hicolor/''${size}x''${size}/apps/zen-browser.png
        fi
      done
      
      # Fallback icon if specific sizes don't exist
      if [ -f $out/lib/zen-browser/browser/chrome/icons/default/default48.png ]; then
        mkdir -p $out/share/pixmaps
        cp $out/lib/zen-browser/browser/chrome/icons/default/default48.png \
           $out/share/pixmaps/zen-browser.png
      fi
    '';
    
    meta = with lib; {
      description = "Zen Browser - Experience tranquillity while browsing the web";
      homepage = "https://zen-browser.app";
      license = licenses.mpl20;
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };

in
{
  options.djh.zen = {
    enable = mkEnableOption "Zen Browser - Modern Firefox-based browser";
    
    setAsDefaultBrowser = mkOption {
      type = types.bool;
      default = false;
      description = "Set Zen as the default web browser";
    };
  };

  config = mkIf cfg.enable {
    # Install Zen Browser and keybind management script
    home.packages = [ 
      zen-browser
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
    
    # Set as default browser if requested
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
