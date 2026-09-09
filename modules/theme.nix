{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.theme = {
    enable = mkEnableOption "Catppuccin theme for entire system";
    flavor = mkOption {
      type = types.enum [ "mocha" "frappe" "macchiato" "latte" ];
      default = "mocha";
      description = "Catppuccin flavor to use";
    };
  };

  config = mkIf config.djh.theme.enable {
    # GTK Theme
    gtk = {
      enable = true;
      theme = {
        name = "Catppuccin-Mocha-Standard-Mauve-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
          size = "standard";
          tweaks = [ "rimless" "black" ];
          variant = "mocha";
        };
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Catppuccin-Mocha-Dark-Cursors";
        size = 24;
        package = pkgs.catppuccin-cursors.mochaDark;
      };
    };

    # Qt/KDE Theme
    qt = {
      enable = true;
      platformTheme = "gtk";
      style = {
        name = "gtk2";
      };
    };

    # Dconf Settings (GSettings)
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Catppuccin-Mocha-Standard-Mauve-Dark";
        icon-theme = "Papirus-Dark";
        cursor-theme = "Catppuccin-Mocha-Dark-Cursors";
        cursor-size = 24;
        color-scheme = "prefer-dark";
      };
    };

    # Home packages
    home.packages = with pkgs; [
      # Catppuccin themes
      catppuccin-gtk
      catppuccin-cursors
      papirus-icon-theme

      # Additional theming tools
      lxappearance  # GTK theme selector
      qt5.full      # Qt components with Catppuccin
    ];

    # Environment variables for consistent theming
    home.sessionVariables = {
      GTK_THEME = "Catppuccin-Mocha-Standard-Mauve-Dark";
      QT_STYLE_OVERRIDE = "gtk";
    };

    # Neovim Catppuccin theme (if Neovim is enabled)
    # This will be in the neovim module
  };
}
