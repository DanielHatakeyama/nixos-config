{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.desktop = {
    enable = mkEnableOption "Desktop integration for Nix applications";
  };

  config = mkIf config.djh.desktop.enable {
    # Enable XDG integration
    xdg.enable = true;
    
    # Ensure proper desktop file integration
    targets.genericLinux.enable = true;
    
    # Create desktop files directory if it doesn't exist
    home.file.".local/share/applications/.keep".text = "";
    
    # Add a script to update desktop database after Home Manager activation
    home.activation.updateDesktopDatabase = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH="${pkgs.desktop-file-utils}/bin:$PATH"
      
      # Create applications directory if it doesn't exist
      mkdir -p ${config.home.homeDirectory}/.local/share/applications
      
      # Update desktop database
      if command -v update-desktop-database >/dev/null 2>&1; then
        $DRY_RUN_CMD update-desktop-database ${config.home.homeDirectory}/.local/share/applications
      fi
      
      # Update icon cache if gtk is available
      if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        for dir in ${config.home.homeDirectory}/.local/share/icons ${config.home.homeDirectory}/.nix-profile/share/icons; do
          if [ -d "$dir" ]; then
            $DRY_RUN_CMD gtk-update-icon-cache -q -t -f "$dir" 2>/dev/null || true
          fi
        done
      fi
    '';
  };
}
