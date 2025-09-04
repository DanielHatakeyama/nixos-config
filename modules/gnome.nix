{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.gnome = {
    enable = mkEnableOption "GNOME desktop configuration";
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
    };
  };
}
