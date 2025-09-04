{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.tmux = {
    enable = mkEnableOption "Tmux terminal multiplexer configuration";
    
    terminal = mkOption {
      type = types.str;
      default = "screen-256color";
      description = "Default terminal setting for tmux";
    };
    
    prefix = mkOption {
      type = types.str;
      default = "C-Space";
      description = "Tmux prefix key";
    };
  };

  config = mkIf config.djh.tmux.enable {
    programs.tmux = {
      enable = true;
      
      # Basic tmux configuration
      terminal = config.djh.tmux.terminal;
      prefix = config.djh.tmux.prefix;
      
      # Enable mouse support
      mouse = true;
      
      # Use vi mode keys
      keyMode = "vi";
      
      # Custom key bindings from your config
      extraConfig = ''
        # Custom prefix (also set C-a as secondary)
        set -g prefix C-a
        unbind C-b
        
        # Pane splitting shortcuts
        unbind %
        bind | split-window -h
        
        unbind '"'
        bind - split-window -v
        
        # Config reload
        unbind r
        bind r source-file ~/.config/tmux/tmux.conf
        
        # Pane resizing shortcuts
        bind -r k resize-pane -U 5
        bind -r j resize-pane -D 5
        bind -r l resize-pane -R 5
        bind -r h resize-pane -L 5
        
        # Maximize pane toggle
        bind -r m resize-pane -Z
        
        # Vi mode copy bindings
        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind-key -T copy-mode-vi 'y' send -X copy-selection
        
        # Don't exit copy mode after dragging with mouse
        unbind -T copy-mode-vi MouseDragEnd1Pane
        
        # Plugin configurations
        set -g @tmux_power_theme 'cyan'
        set -g @resurrect-capture-pane-contents 'on'
        set -g @continuum-restore 'on'
        
        # Disable wrap-around on seamless Vim ⇄ tmux navigation
        unbind -n C-h
        unbind -n C-j
        unbind -n C-k
        unbind -n C-l
        
        # Detect when the current pane is running Vim/Neovim
        set -g @is_vim 'ps -o state=,comm= -t "#{pane_tty}" | grep -iqE "^[^TXZ ]+ +(view|l?n?vim?x?)(diff)?$"'
        
        # Re-bind the keys with conditional, no-wrap logic
        bind -n C-h if-shell "#{@is_vim}" 'send-keys C-h'  'if -F "#{pane_at_left}"   "" "select-pane -L"'
        bind -n C-j if-shell "#{@is_vim}" 'send-keys C-j'  'if -F "#{pane_at_bottom}" "" "select-pane -D"'
        bind -n C-k if-shell "#{@is_vim}" 'send-keys C-k'  'if -F "#{pane_at_top}"    "" "select-pane -U"'
        bind -n C-l if-shell "#{@is_vim}" 'send-keys C-l'  'if -F "#{pane_at_right}"  "" "select-pane -R"'
      '';
      
      # Tmux plugins from your configuration
      plugins = with pkgs.tmuxPlugins; [
        # Core navigation and workflow plugins
        vim-tmux-navigator  # Navigate between vim and tmux panes with Ctrl-hjkl
        
        # Session management
        resurrect          # Persist tmux sessions after computer restart
        continuum          # Automatically saves sessions every 15 minutes
        
        # Theme - using power-theme as alternative to themepack
        {
          plugin = power-theme;
          extraConfig = ''
            set -g @tmux_power_theme 'cyan'
          '';
        }
      ];
    };
    
    # Install fzf for tmux-fzf plugin functionality
    home.packages = with pkgs; [
      fzf
    ];
    
    # Create a desktop entry for tmux (useful for launching from application menu)
    xdg.desktopEntries.tmux = mkIf pkgs.stdenv.isLinux {
      name = "Tmux";
      comment = "Terminal multiplexer";
      exec = "${pkgs.kitty}/bin/kitty tmux";
      icon = "terminal";
      terminal = false;
      categories = [ "System" "TerminalEmulator" ];
    };
  };
}
