{ config, pkgs, ... }:

{
  
  # Programs to have default installed and configured on the system. # THIS IS HOME MANAGER YOU FREAK THIS NEED TO BE SO REDONE XD
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
    # ./modules/theme.nix  # Temporarily disabled - causing flake error
    ./modules/tmux.nix
    ./modules/tridactyl.nix
    ./modules/zen.nix
  ];

  services = {
    udiskie = {
      enable = true;
    };
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "djh";
  home.homeDirectory = "/home/djh";
  nixpkgs.config.allowUnfree = true;

  djh.zen.enable = true;
  djh.gnome.enable = true;               # Enable GNOME tweaks/keybindings too
  djh.gnome.enableTilingExtensions = true;  # Enable Pop Shell tiling in GNOME
  djh.hyprland.enable = true;            # Primary desktop environment
  djh.kitty.enable = true;
  djh.neovim.enable = true;  # Re-enabled with standalone configuration
  djh.tmux.enable = true;
  djh.tridactyl.enable = true;  # Browser vim-like navigation
  djh.desktop-integration.enable = true;
  djh.gaming.enable = true;              # Enable Steam, Minecraft with enhanced auth
  djh.audio.enable = true;               # Simple and stable audio configuration
  djh.claude-code.enable = true;
  # djh.theme.enable = true;               # Enable Catppuccin theme across system (disabled temporarily)

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.

  home.packages = import ./programs/packages.nix { inherit pkgs; };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/djh/etc/profile.d/hm-session-vars.sh
  #
  #

  programs.hyprshot.enable = true;
  
  
  home.sessionVariables = {
    BROWSER = "firefox";
    DEFAULT_BROWSER = "firefox";
    NIX_BUILD_SHELL = "${pkgs.bash}/bin/bash";
    # WebRTC and PipeWire support for Chromium (Google Meet microphone)
    WEBRTC_USE_PIPEWIRE = "1";
    PULSE_PROP_media_role = "phone";
  };

  # Set Firefox as default browser
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

  # Chromium configuration for WebRTC support (Google Meet microphone)
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    commandLineArgs = [
      "--enable-webrtc"
      "--enable-audio-input-permissions"
      "--disable-setuid-sandbox"
    ];
  };


  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
