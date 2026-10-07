{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins"; # Vi-like key bindings

    # Enable oh-my-zsh
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell"; # Default theme, you can change this
      plugins = [
        "git"
        "sudo"
        "docker"
        "history-substring-search"
      ];
    };

    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      ignoreDups = true;
    };

    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      hm = "home-manager";
      cd = "z"; # Alias cd to zoxide
      nix-shell = "nix-shell-zsh"; # Use zsh in nix-shell by default
      audio = "pavucontrol"; # Quick access to audio control GUI
      audio-list = "pactl list short sinks"; # List available audio outputs
      app = "app-launcher"; # Vim-friendly app launcher
    };

    # Add visual indicator when in nix-shell or nix develop
    #
    # This used to also force the default sink/source back to the laptop
    # speakers/mic on every single shell startup — removed (2026-10-06):
    # it unconditionally stomped on whatever the user had just explicitly
    # switched to (e.g. via the SUPER+F1/F2/F3 binds in modules/hyprland.nix,
    # which it was silently fighting), and NORTH_STAR.md already called this
    # out as a band-aid to remove ("No `pactl` commands in shell startup" —
    # device policy belongs in WirePlumber, declaratively, not here).
    initContent = ''
      # Visual indicator when in nix-shell or nix develop
      if [[ -n "$IN_NIX_SHELL" ]] || [[ -n "$DIRENV_FILE" ]]; then
        PROMPT="❄️  $PROMPT"
      fi
    '';
  };

  # Enable zoxide - a smarter cd command that learns your habits
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Enable direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # Use nix-direnv for faster, cached nix-shell evaluation
  };
}
