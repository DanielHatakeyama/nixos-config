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
        
        # Keybindings for window focus (Alt replaces Cmd from macOS)
        window-focus-up = [ "<Alt>k" ];
        window-focus-down = [ "<Alt>j" ];  
        window-focus-left = [ "<Alt>h" ];
        window-focus-right = [ "<Alt>l" ];
        
        # Window movement keybindings (Alt+Shift replaces Cmd+Shift)
        window-move-up = [ "<Alt><Shift>k" ];
        window-move-down = [ "<Alt><Shift>j" ];
        window-move-left = [ "<Alt><Shift>h" ];
        window-move-right = [ "<Alt><Shift>l" ];
        
        # Window swapping/warping (equivalent to yabai --warp)
        window-swap-up = [ "<Alt><Ctrl><Shift>k" ];
        window-swap-down = [ "<Alt><Ctrl><Shift>j" ];
        window-swap-left = [ "<Alt><Ctrl><Shift>h" ];
        window-swap-right = [ "<Alt><Ctrl><Shift>l" ];
        
        # Window resizing (basic controls)
        window-resize-width-inc = [ "<Alt><Ctrl>l" ];
        window-resize-width-dec = [ "<Alt><Ctrl>h" ];
        window-resize-height-inc = [ "<Alt><Ctrl>k" ];
        window-resize-height-dec = [ "<Alt><Ctrl>j" ];
        
        # Toggle floating (equivalent to yabai float/unfloat with 4:4:1:1:2:2 grid) - Using advanced script
        window-toggle-float = []; # Disable default, use custom keybinding below
        window-snap-center = true;
        window-snap-one-third = false;
        
        # Toggle always on top
        window-toggle-always-on-top = [ "<Alt><Shift>f" ];
        
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
        
        # Workspace switching (equivalent to yabai space focus)
        switch-to-workspace-1 = [ "<Alt>1" ];
        switch-to-workspace-2 = [ "<Alt>2" ];
        switch-to-workspace-3 = [ "<Alt>3" ];
        switch-to-workspace-4 = [ "<Alt>4" ];
        switch-to-workspace-5 = [ "<Alt>5" ];
        switch-to-workspace-6 = [ "<Alt>6" ];
        switch-to-workspace-7 = [ "<Alt>7" ];
        switch-to-workspace-8 = [ "<Alt>8" ];
        switch-to-workspace-9 = [ "<Alt>9" ];
        
        # Move window to workspace (equivalent to yabai window --space)
        move-to-workspace-1 = [ "<Alt><Shift>1" ];
        move-to-workspace-2 = [ "<Alt><Shift>2" ];
        move-to-workspace-3 = [ "<Alt><Shift>3" ];
        move-to-workspace-4 = [ "<Alt><Shift>4" ];
        move-to-workspace-5 = [ "<Alt><Shift>5" ];
        move-to-workspace-6 = [ "<Alt><Shift>6" ];
        move-to-workspace-7 = [ "<Alt><Shift>7" ];
        move-to-workspace-8 = [ "<Alt><Shift>8" ];
        move-to-workspace-9 = [ "<Alt><Shift>9" ];
        
        # Workspace navigation (equivalent to yabai space --focus prev/next)
        switch-to-workspace-left = [ "<Alt><Ctrl>h" ];
        switch-to-workspace-right = [ "<Alt><Ctrl>l" ];
        
        # Window management
        close = [ "<Alt><Shift>q" ];  # Equivalent to skhd cmd+shift+q
        toggle-fullscreen = [ "<Alt><Shift>f" ];  # Changed to avoid conflict with float
        toggle-maximized = [ "<Alt>m" ];
        minimize = [ "<Alt>comma" ];
        
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
        
        # Recent workspace switching (equivalent to alt-tab for spaces)
        switch-to-workspace-last = [ "<Alt><Ctrl>Tab" ];
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
      
      # Terminal launcher (equivalent to quick terminal access)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Alt>Return";
        command = "kitty";
        name = "Launch Terminal";
      };
      
      # Application launcher (equivalent to Spotlight)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Alt>r";
        command = "gnome-shell -c 'imports.ui.main.overview.show()'";
        name = "Application Launcher";
      };
      
      # File manager  
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Alt>e";
        command = "nautilus";
        name = "File Manager";
      };
      
      # Modal resize system (Alt+p enters resize mode) - Using advanced window management script
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        binding = "<Alt>p";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh resize-mode";
        name = "Enter Resize Mode";
      };
      
      # Recent workspace switching (Alt+Tab for workspaces, matching yabai alt-tab behavior)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        binding = "<Alt><Ctrl>Tab";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh recent-workspace";
        name = "Recent Workspace Switch";
      };
      
      # WASD navigation mode (Alt+w enters WASD mode, matching skhd wasd mode)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
        binding = "<Alt>w";
        command = "${config.home.homeDirectory}/.config/home-manager/scripts/gnome-window-manager.sh wasd-mode";
        name = "Enter WASD Navigation Mode";
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
