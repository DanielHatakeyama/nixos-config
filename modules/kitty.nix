{ config, lib, pkgs, ... }:

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
      default = null;
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
