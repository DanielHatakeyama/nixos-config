{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.desktop-integration = {
    enable = mkEnableOption "Desktop integration for Nix packages";
    
    # Allow users to specify additional packages that need desktop file fixes
    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to ensure desktop files for";
      example = [ pkgs.obsidian pkgs.discord ];
    };
  };

  config = mkIf config.djh.desktop-integration.enable {
    # Ensure XDG desktop integration is enabled
    targets.genericLinux.enable = pkgs.stdenv.isLinux;
    
    # Force desktop file updates for common problematic packages
    xdg.desktopEntries.obsidian = {
      name = "Obsidian";
      comment = "Knowledge base";
      exec = "obsidian %U";
      icon = "obsidian";
      terminal = false;
      categories = [ "Office" ];
      mimeType = [ "x-scheme-handler/obsidian" ];
    };
    
    # Also manually copy desktop files from nix packages to ensure they work
    home.activation.copyDesktopFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Copy desktop files from problematic Nix packages
      PACKAGES=("obsidian")
      
      for pkg in "''${PACKAGES[@]}"; do
        PKG_PATH=$(command -v "$pkg" 2>/dev/null) || continue
        NIX_STORE_PATH=$(dirname "$(dirname "$PKG_PATH")")
        
        if [ -d "$NIX_STORE_PATH/share/applications" ]; then
          echo "Copying desktop files for $pkg"
          mkdir -p ~/.local/share/applications
          cp "$NIX_STORE_PATH"/share/applications/*.desktop ~/.local/share/applications/ 2>/dev/null || true
        fi
      done
    '';
    
    # Ensure desktop database is updated
    xdg.mimeApps.enable = true;
    
    # Script to manually fix desktop files for any package
    home.packages = [ 
      (pkgs.writeShellScriptBin "nix-desktop-fix" ''
        #!/bin/bash
        
        # Script to manually create desktop files for Nix packages
        
        if [ -z "$1" ]; then
          echo "Usage: nix-desktop-fix <package-name>"
          echo "Example: nix-desktop-fix obsidian"
          exit 1
        fi
        
        PACKAGE_NAME="$1"
        PACKAGE_PATH=$(which "$PACKAGE_NAME" 2>/dev/null)
        
        if [ -z "$PACKAGE_PATH" ]; then
          echo "Error: Package '$PACKAGE_NAME' not found in PATH"
          exit 1
        fi
        
        # Get the nix store path
        NIX_PATH=$(dirname "$(dirname "$PACKAGE_PATH")")
        
        # Look for desktop files in the package
        DESKTOP_FILES=$(find "$NIX_PATH/share/applications" -name "*.desktop" 2>/dev/null)
        
        if [ -z "$DESKTOP_FILES" ]; then
          echo "No desktop files found for $PACKAGE_NAME"
          echo "Creating a basic desktop file..."
          
          mkdir -p ~/.local/share/applications
          cat > ~/.local/share/applications/"$PACKAGE_NAME".desktop << EOF
        [Desktop Entry]
        Name=$PACKAGE_NAME
        Comment=Application installed via Nix
        Exec=$PACKAGE_PATH %U
        Icon=$PACKAGE_NAME
        Type=Application
        Categories=Application;
        Terminal=false
        EOF
          echo "Created ~/.local/share/applications/$PACKAGE_NAME.desktop"
        else
          echo "Found desktop files for $PACKAGE_NAME:"
          for desktop_file in $DESKTOP_FILES; do
            filename=$(basename "$desktop_file")
            echo "Copying $filename to ~/.local/share/applications/"
            mkdir -p ~/.local/share/applications
            cp "$desktop_file" ~/.local/share/applications/
          done
        fi
        
        # Update desktop database
        update-desktop-database ~/.local/share/applications 2>/dev/null || true
        echo "Desktop database updated!"
      '')
    ];
  };
}
