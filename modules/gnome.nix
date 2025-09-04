{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.gnome = {
    enable = mkEnableOption "GNOME desktop configuration";
    
    altTabSwitchesWindows = mkOption {
      type = types.bool;
      default = true;
      description = "Whether Alt+Tab should switch between individual windows instead of applications";
    };
  };

  config = mkIf config.djh.gnome.enable {
    # GNOME-specific packages
    home.packages = with pkgs; [
      gnome-tweaks
      dconf-editor
    ];

    # GTK theme configuration (Graphite theme)
    gtk = {
      enable = true;
      theme = {
        name = "Graphite-Dark";
        package = pkgs.graphite-gtk-theme;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    # GNOME-specific dconf settings
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Graphite-Dark";
        icon-theme = "Papirus-Dark";
        cursor-theme = "Adwaita";
      };
      
      # Window switching behavior - configurable via altTabSwitchesWindows option
      "org/gnome/desktop/wm/keybindings" = {
        # Always improve Alt+` (backtick) for window switching within applications
        switch-group = [ "<Alt>grave" "<Alt>Above_Tab" ];
        switch-group-backward = [ "<Shift><Alt>grave" "<Shift><Alt>Above_Tab" ];
      } // (if config.djh.gnome.altTabSwitchesWindows then {
        # Make Alt+Tab cycle through windows instead of applications
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
        
        # Move application switching to Super+Tab
        switch-applications = [ "<Super>Tab" ];
        switch-applications-backward = [ "<Shift><Super>Tab" ];
      } else {});
    };
  };
}
