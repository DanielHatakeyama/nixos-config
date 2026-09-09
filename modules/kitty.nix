{ config, lib, pkgs, ... }:


# It might be time to try a different terminal. I should at least see if i can do a speed comparison. 
# TODO: remove the escape sudo behavior  i hate it.


with lib;

{
  options.djh.kitty = {
    enable = mkEnableOption "Kitty terminal configuration";
    
    font = {
      name = mkOption {
        type = types.str;
        default = "FiraCode Nerd Font";
        description = "Font family to use in Kitty";
        example = "Liga SFMono Nerd Font";
      };
      
      size = mkOption {
        type = types.int;
        default = 13;
        description = "Font size in points";
      };
    };
    
    theme = mkOption {
      type = types.nullOr types.str;
      default = "Catppuccin-Mocha";
      description = "Kitty theme name from kitty-themes collection";
      example = "SpaceGray_Eighties";
    };
  };

  config = mkIf config.djh.kitty.enable {
    # Install the Nerd Font required for Kitty
    home.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
    ];

    # Setup kitty background on activation
    home.activation.setupKittyBackground = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${config.home.homeDirectory}/.config/home-manager/scripts/setup-kitty-background.sh || true
    '';

    # Use the official Home Manager kitty module
    programs.kitty = {
      enable = true;
      
      # Font configuration
      font = {
        name = config.djh.kitty.font.name;
        size = config.djh.kitty.font.size;
      };
      
      # Theme configuration
      themeFile = config.djh.kitty.theme;
      
      # Key mappings for better editing experience
      keybindings = {
        
        # Ctrl+Backspace to delete word (like Windows/Mac)
        "ctrl+backspace" = "send_text all \\x17";  # Send Ctrl+W to delete word

        # IDK What this vibe code is
        # Ctrl+Delete to delete word forward
        "ctrl+delete" = "send_text all \\x1b\\x64";  # Send Alt+d to delete word forward
        
        # Additional useful bindings
        "ctrl+left" = "send_text all \\x1bb";   # Move word left
        "ctrl+right" = "send_text all \\x1bf";  # Move word right
        
        # Disable Ctrl+L from clearing screen
        "ctrl+l" = "no_op";

        # Disable annoying sudo escape behavior
        "esc" = "no_op";
      };
      
      # Terminal settings based on your archived config, adapted for Linux
      settings = {
        # Shell configuration - use zsh as the default shell
        shell = "${pkgs.zsh}/bin/zsh";
        # Performance optimizations
        repaint_delay = 8;
        input_delay = 1;
        resize_draw_strategy = "blank";
        resize_debounce_time = "0.001";
        
        # Window appearance
        window_margin_width = 4;
        remember_window_size = false;
        confirm_os_window_close = -2;
        
        # Cursor settings
        cursor_blink_interval = 0;
        
        # Tab bar configuration (matching your archived config)
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_activity_symbol = "";
        tab_title_max_length = 30;
        tab_title_template = "{fmt.fg.red}{bell_symbol}{fmt.fg.tab} {index}: ({tab.active_oldest_exe}) {title} {activity_symbol}";
        
        # Linux-specific optimizations
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
        
        # Static background opacity
        background_opacity = "0.7";
        
        # Custom background image
        background_image = "~/.config/kitty/background.png";
        background_image_layout = "cscaled";  # Constrained scaling - maintains aspect ratio
        background_image_linear = true;
        background_tint = "0.9";  # Darker tint for better text readability
        background_blur = "40";  # Much more blur for an even softer effect
      };
      
      # Nerd Font symbol mappings from your archived config
      extraConfig = ''
        # Nerd Font symbol mappings for better icon support in LazyVim
        symbol_map U+F0001-U+F1af0 ${config.djh.kitty.font.name}
        symbol_map U+F8FF,U+100000-U+1018C7 ${config.djh.kitty.font.name}
        symbol_map U+E5FA-U+E6AC ${config.djh.kitty.font.name}
        symbol_map U+E700-U+E7C5 ${config.djh.kitty.font.name}
        symbol_map U+EA60-U+EBEB ${config.djh.kitty.font.name}
        symbol_map U+E0A0-U+E0A2,U+E0B0-U+E0B3 ${config.djh.kitty.font.name}
        
        # Ensure proper font fallback for missing glyphs
        force_ltr = no
      '';
      
      # Enable shell integration for better terminal experience (prioritize zsh)
      shellIntegration = {
        enableBashIntegration = false;  # Disable bash integration
        enableFishIntegration = false;  # Disable fish integration
        enableZshIntegration = true;    # Enable zsh integration with oh-my-zsh
      };
    };
    
    # Set Kitty as the default terminal for XDG applications
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/terminal" = "kitty.desktop";
      "application/x-terminal-emulator" = "kitty.desktop";
    };
    
    # Modern XDG terminal specification support
    xdg.terminal-exec = {
      enable = true;
      settings = {
        default = [ "kitty.desktop" ];
        GNOME = [ "kitty.desktop" ];
      };
    };
    
    # Create a desktop file for better integration
    xdg.desktopEntries.kitty = {
      name = "Kitty Terminal";
      comment = "Fast, feature-rich, GPU based terminal emulator";
      exec = "kitty";
      icon = "kitty";
      terminal = false;
      categories = [ "System" "TerminalEmulator" ];
      mimeType = [ "x-scheme-handler/terminal" "application/x-terminal-emulator" ];
      startupNotify = true;
    };
  };
}
