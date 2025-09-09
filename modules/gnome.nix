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

    enableTilingExtensions = mkOption {
      type = types.bool;
      default = true;
      description = "Enable tiling window management extensions (Forge, PaperWM)";
    };

    enableYabaiLikeKeybindings = mkOption {
      type = types.bool;
      default = true;
      description = "Enable yabai/skhd-like keyboard shortcuts for window management";
    };

    workspaceLabels = mkOption {
      type = types.listOf types.str;
      default = [ "code" "browser" "terminal" "chat" "code2" "daemon" "notes" "chat1" "chat2" ];
      description = "Labels for workspaces (corresponds to yabai space labels)";
    };
  };

  config = mkIf config.djh.gnome.enable {
    # GNOME-specific packages
    home.packages = with pkgs; [
      gnome-tweaks
      dconf-editor
      # Additional packages for advanced window management
      wmctrl           # Window management control
      xdotool          # X11 automation (for some advanced scripts)
      libnotify        # Desktop notifications for mode feedback
      glib             # Includes gdbus for D-Bus communication with GNOME Shell
    ] ++ optionals config.djh.gnome.enableTilingExtensions [
      # Note: Extensions are installed through dconf settings below
    ];

    # GNOME Extensions configuration (declarative)
    dconf.settings = {
      # Keyboard layout and key mapping configuration
      "org/gnome/desktop/input-sources" = {
        # Swap Alt and Super keys system-wide
        xkb-options = [ "altwin:swap_alt_win" ];
      };

      # GNOME Extensions configuration and shell behavior
      "org/gnome/shell" = {
        # Always show workspace thumbnails in overview
        always-show-log-out = true;
        # Enable workspace switcher in overview  
        workspace-switcher-should-show = true;
      } // (if config.djh.gnome.enableTilingExtensions then {
        # Enable tiling extensions
        enabled-extensions = [
          "forge@jmmaranan.com"          # Tiling window manager
          "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        ];
      } else {
        # Basic extensions only
        enabled-extensions = [
          "workspace-indicator@gnome-shell-extensions.gcampax.github.com" 
        ];
      });

      # Forge extension settings (comprehensive yabai-like tiling)
      "org/gnome/shell/extensions/forge" = {
        # Core tiling behavior (matching yabai config)
        tiling-mode-enabled = true;
        auto-split-enabled = true;
        split-border-toggle = true;
        
        # Window gaps (equivalent to yabai: top/bottom/left/right_padding 6, window_gap 6)
        window-gap-size = 6;
        window-gap-size-increment = 1;
        
        # Layout settings (equivalent to yabai: layout bsp, split_ratio 0.50, auto_balance off)
        css-last-applied = ""; # Reset any custom styling
        quick-settings-enabled = false;
        
        # Focus and mouse behavior (matching yabai: mouse_follows_focus on, focus_follows_mouse on)
        focus-border-toggle = true;
        focus-border-size = 2;
        
        # Window opacity (matching yabai: active_window_opacity 1.0, normal_window_opacity 0.90)
        window-opacity-focus = 100;
        window-opacity-unfocus = 90;
        
        # Disable focus wrapping (matching yabai: focus_wraps off)
        focus-wraps = false;
        
        # Window focus navigation (matching skhd cmd+hjkl exactly)
        # Note: After key swap, these use physical Super key (was Alt in config)
        window-focus-up = [ "<Super>k" ];
        window-focus-down = [ "<Super>j" ];  
        window-focus-left = [ "<Super>h" ];
        window-focus-right = [ "<Super>l" ];
        
        # Window movement/warping (matching skhd cmd+shift+hjkl)
        window-move-up = [ "<Super><Shift>k" ];
        window-move-down = [ "<Super><Shift>j" ];
        window-move-left = [ "<Super><Shift>h" ];
        window-move-right = [ "<Super><Shift>l" ];
        
        # Window swapping (equivalent to yabai --warp, using Ctrl as modifier)
        window-swap-up = [ "<Super><Ctrl><Shift>k" ];
        window-swap-down = [ "<Super><Ctrl><Shift>j" ];
        window-swap-left = [ "<Super><Ctrl><Shift>h" ];
        window-swap-right = [ "<Super><Ctrl><Shift>l" ];
        
        # Disable window resizing keybindings (will use modal system instead)
        window-resize-width-inc = [];
        window-resize-width-dec = [];
        window-resize-height-inc = [];
        window-resize-height-dec = [];
        
        # Toggle floating - DISABLED (using custom script instead)
        window-toggle-float = [];
        
        # Always on top toggle (useful for floating windows)
        window-toggle-always-on-top = [ "<Super><Shift>t" ];
        
        # Split direction control (equivalent to yabai split direction)
        window-toggle-split = [ "<Alt>v" ];
        
        # BSP layout controls
        window-gap-hidden-on-single = false;
        workspace-skip-tile = [];
        
        # Multi-monitor behavior
        move-pointer-focus-enabled = true;
        move-pointer-focus-delay = 100;
        
        # Drag-to-tile settings
        drag-to-tile = true;
        drag-to-tile-gutter = 20;
      };

      # Auto-move windows to specific workspaces (like yabai rules)
      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "code.desktop:1"              # VS Code -> workspace 1 (code)
          "cursor.desktop:1"            # Cursor -> workspace 1 (code)  
          "zen-browser.desktop:2"       # Zen Browser -> workspace 2 (browser)
          "firefox.desktop:2"           # Firefox -> workspace 2 (browser)
          "torbrowser.desktop:2"        # Tor Browser -> workspace 2 (browser) - fixed name
          "org.gnome.Console.desktop:3" # Console -> workspace 3 (terminal)
          "kitty.desktop:3"             # Kitty -> workspace 3 (terminal)
          "discord.desktop:4"           # Discord -> workspace 4 (chat)
          "slack.desktop:8"             # Slack -> workspace 8 (chat1)
          "org.gnome.TextEditor.desktop:7"  # Text Editor -> workspace 7 (notes)
        ];
      };

      # GNOME Desktop Interface settings
      "org/gnome/desktop/interface" = {
        gtk-theme = "Graphite-Dark";
        icon-theme = "Papirus-Dark";
        cursor-theme = "Adwaita";
        # Show weekday in top bar (like macOS)
        clock-show-weekday = true;
        # Enable hot corners for activities overview
        enable-hot-corners = true;
      };

      # Workspace settings (equivalent to yabai space labels)
      "org/gnome/desktop/wm/preferences" = {
        # Set number of workspaces to match yabai setup
        num-workspaces = length config.djh.gnome.workspaceLabels;
        workspace-names = config.djh.gnome.workspaceLabels;
        # Focus follows mouse (like yabai mouse_follows_focus)
        focus-mode = "click";  # Can be "click" or "sloppy" (focus follows mouse)
        # Auto-raise windows
        auto-raise = false;
        auto-raise-delay = 500;
      };

      # Mouse and touchpad behavior (equivalent to yabai mouse settings)
      "org/gnome/desktop/peripherals/mouse" = {
        # Natural scrolling like macOS
        natural-scroll = true;
        # Acceleration profile
        accel-profile = "adaptive";
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        # Natural scrolling
        natural-scroll = true;
        # Tap to click
        tap-to-click = true;
        # Two finger scroll
        two-finger-scrolling-enabled = true;
        # Disable while typing
        disable-while-typing = true;
      };
      # Window Manager Keybindings (inspired by skhd configuration)
      "org/gnome/desktop/wm/keybindings" = {
        # Window switching behavior - configurable via altTabSwitchesWindows option
        # Always improve Alt+` (backtick) for window switching within applications
        switch-group = [ "<Alt>grave" "<Alt>Above_Tab" ];
        switch-group-backward = [ "<Shift><Alt>grave" "<Shift><Alt>Above_Tab" ];
        
        # Workspace switching (matching skhd cmd+1-9 exactly)
        # Note: After key swap, these use physical Super key
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];
        switch-to-workspace-6 = [ "<Super>6" ];
        switch-to-workspace-7 = [ "<Super>7" ];
        switch-to-workspace-8 = [ "<Super>8" ];
        switch-to-workspace-9 = [ "<Super>9" ];
        
        # Move window to workspace (matching skhd cmd+shift+1-9)
        move-to-workspace-1 = [ "<Super><Shift>1" ];
        move-to-workspace-2 = [ "<Super><Shift>2" ];
        move-to-workspace-3 = [ "<Super><Shift>3" ];
        move-to-workspace-4 = [ "<Super><Shift>4" ];
        move-to-workspace-5 = [ "<Super><Shift>5" ];
        move-to-workspace-6 = [ "<Super><Shift>6" ];
        move-to-workspace-7 = [ "<Super><Shift>7" ];
        move-to-workspace-8 = [ "<Super><Shift>8" ];
        move-to-workspace-9 = [ "<Super><Shift>9" ];
        
        # Workspace navigation (matching skhd cmd+ctrl+h/l)
        switch-to-workspace-left = [ "<Super><Ctrl>h" ];
        switch-to-workspace-right = [ "<Super><Ctrl>l" ];
        
        # Window management (matching skhd exactly)
        close = [ "<Super><Shift>q" ];  # Matching skhd cmd+shift+q
        toggle-fullscreen = [ "<Super>f" ];  # Standard fullscreen toggle
        toggle-maximized = [ "<Super>m" ];
        minimize = [ "<Super>comma" ];
        
        # Recent workspace switching (matching skhd alt+tab behavior)
        switch-to-workspace-last = [ "<Alt>Tab" ];
        
        # Window movement between monitors (equivalent to yabai display focus)
        move-to-monitor-left = [ "<Alt><Shift><Ctrl>h" ];
        move-to-monitor-right = [ "<Alt><Shift><Ctrl>l" ];
        move-to-monitor-up = [ "<Alt><Shift><Ctrl>k" ];
        move-to-monitor-down = [ "<Alt><Shift><Ctrl>j" ];
        
        # Activities overview (replaces Mission Control)
        panel-main-menu = [ "<Super>space" ];
        
        # Show desktop (equivalent to F11 on macOS)
        show-desktop = [ "<Super>d" ];
        
        # Window snapping (basic tiling)
        toggle-tiled-left = [ "<Super>Left" ];
        toggle-tiled-right = [ "<Super>Right" ];
      } // (if config.djh.gnome.altTabSwitchesWindows then {
        # Make Alt+Tab cycle through windows instead of applications
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
        
        # Move application switching to Super+Tab
        switch-applications = [ "<Super>Tab" ];
        switch-applications-backward = [ "<Shift><Super>Tab" ];
      } else {});

      # Custom keybindings for additional yabai-like functionality  
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
        ];
      };
      
      # Float toggle (matching skhd alt+f with 4:4:1:1:2:2 grid) - Using advanced script
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Alt>f";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh float-toggle";
        name = "Float Toggle with Grid";
      };
      
      # Modal resize system (matching skhd alt+r and alt+p for resize mode)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Alt>r";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh resize-mode";
        name = "Enter Resize Mode";
      };
      
      # Alternative resize mode binding (matching skhd alt+p)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Alt>p";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh resize-mode";
        name = "Enter Resize Mode (Alt)";
      };
      
      # WASD navigation mode (matching skhd alt+w for WASD mode)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        binding = "<Alt>w";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh wasd-mode";
        name = "Enter WASD Navigation Mode";
      };
      
      # Recent workspace switching (matching skhd alt+tab behavior exactly)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        binding = "<Alt>Tab";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh recent-workspace";
        name = "Recent Workspace Switch";
      };
      
      # Quick terminal access (useful for development workflow)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
        binding = "<Super>Return";  # Changed to Super since Alt+Return interferes with some apps
        command = "kitty";
        name = "Launch Terminal";
      };
      
      # Shell behavior (moved and consolidated)
      # Note: org/gnome/shell settings are above in the GNOME Extensions section

      # Mutter (GNOME's window manager) settings - Enhanced for tiling
      "org/gnome/mutter" = {
        # Enable experimental features for better tiling support
        experimental-features = [ "scale-monitor-framebuffer" "rt-scheduler" ];
        
        # Window dragging behavior
        attach-modal-dialogs = false;
        
        # Focus change settings (equivalent to yabai responsiveness)
        focus-change-on-pointer-rest = true;
        
        # Edge tiling behavior
        edge-tiling = true;
        
        # Dynamic workspaces (set to false for fixed workspace count like yabai)
        dynamic-workspaces = false;
        
        # Workspaces on primary display only (yabai-like behavior)
        workspaces-only-on-primary = false; # Allow multi-monitor workspaces
        
        # Center new windows (helps with floating window placement)
        center-new-windows = true;
        
        # Auto-maximize behavior
        auto-maximize = false; # Disable to allow tiling control
        
        # Window animations (matching yabai: window_animation_duration 0.0)
        resize-with-right-button = true;
        
        # Overlay key behavior (disable Super key overlay to avoid conflicts)
        overlay-key = ""; # Disable overlay key to free up Super for tiling
      };
    };

    # GTK theme configuration (moved here for proper ordering)
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
  };
}
