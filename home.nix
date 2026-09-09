{ config, pkgs, ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/vscode.nix
    ./programs/zsh.nix
    ./modules/audio-simple.nix
    ./modules/claude-code.nix
    ./modules/desktop-integration.nix
    ./modules/gaming.nix
    ./modules/gnome.nix
    ./modules/hyprland.nix
    ./modules/kitty.nix
    ./modules/neovim.nix
    # ./modules/theme.nix
    ./modules/tmux.nix
    ./modules/tridactyl.nix
    ./modules/zen.nix
  ];

  home.username = "djh";
  home.homeDirectory = "/home/djh";
  home.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;

  # Module enables
  djh.audio.enable = true;
  djh.claude-code.enable = true;
  djh.desktop-integration.enable = true;
  djh.gaming.enable = true;
  djh.gnome.enable = true;
  djh.gnome.enableTilingExtensions = true;
  djh.hyprland.enable = true;
  djh.kitty.enable = true;
  djh.neovim.enable = true;
  djh.tmux.enable = true;
  djh.tridactyl.enable = true;
  djh.zen.enable = true;

  home.packages = import ./programs/packages.nix { inherit pkgs; };

  home.sessionVariables = {
    BROWSER = "firefox";
    DEFAULT_BROWSER = "firefox";
    NIX_BUILD_SHELL = "${pkgs.bash}/bin/bash";
  };

  # Firefox as default browser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };

  programs.hyprshot.enable = true;
  programs.home-manager.enable = true;

  services.udiskie.enable = true;
}
