{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";  # Vi-like key bindings
    
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
      hms = "home-manager switch --flake ~/.config/home-manager#djh";
      cd = "z";  # Alias cd to zoxide
      nix-shell = "nix-shell-zsh";  # Use zsh in nix-shell by default
      audio = "pavucontrol";  # Quick access to audio control GUI
      audio-list = "pactl list short sinks";  # List available audio outputs
      app = "app-launcher";  # Vim-friendly app launcher
    };
    
    # Add visual indicator when in nix-shell or nix develop
    # Also set speakers as default audio output on shell startup
    initContent = ''
      # Set laptop speakers as default audio output
      if command -v pactl &> /dev/null; then
        pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink 2>/dev/null || true
        # Set laptop microphone as default input (prevents Bluetooth headphones from hijacking mic)
        pactl set-default-source alsa_input.pci-0000_00_1f.3.analog-stereo 2>/dev/null || true
      fi
      
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
    nix-direnv.enable = true;  # Use nix-direnv for faster, cached nix-shell evaluation
  };
}
