{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.hyprland = {
    enable = mkEnableOption "Hyprland wayland compositor configuration";
    
    enableTiling = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic tiling behavior";
    };

    gaps = mkOption {
      type = types.int;
      default = 6;
      description = "Window gaps in pixels (matching yabai config)";
    };

    borderSize = mkOption {
      type = types.int;
      default = 2;
      description = "Window border size in pixels";
    };

    workspaceLabels = mkOption {
      type = types.listOf types.str;
      default = [ "code" "browser" "terminal" "chat" "code2" "daemon" "notes" "chat1" "chat2" ];
      description = "Labels for workspaces (corresponds to yabai space labels)";
    };

    terminal = mkOption {
      type = types.str;
      default = "kitty";
      description = "Default terminal emulator";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional Hyprland configuration";
    };
  };

  config = mkIf config.djh.hyprland.enable {
    # Install Hyprland and related packages
    home.packages = with pkgs; [
      hyprland
      hyprpaper        # Wallpaper daemon
      hypridle         # Idle daemon
      hyprlock         # Screen locker
      hyprpicker       # Color picker
      wl-clipboard     # Wayland clipboard utilities
      grim             # Screenshot tool
      slurp            # Area selection for screenshots
      swappy           # Screenshot editor
      rofi-wayland     # Application launcher
      waybar           # Status bar
      dunst            # Notification daemon
      pavucontrol      # Volume control GUI
      brightnessctl    # Brightness control
      playerctl        # Media control
      wlogout          # Logout menu
      wtype            # Wayland typing tool for key injection
      jq               # JSON processor for Hyprland commands
      # Standard cursor themes
      vanilla-dmz      # Simple, standard cursor theme
      adwaita-icon-theme  # GNOME cursor theme
      capitaine-cursors # Mac like cursor
      # Nice fonts for ricing
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      # Wallpaper utilities
      wget             # For downloading wallpapers
      curl             # Alternative download tool

    ];

    # Declaritively create cursor settings
    home.pointerCursor = {
      package = pkgs.capitaine-cursors; # Theme
      name = "capitaine-cursors";       # "capitaine-cursors-white" for light
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    # Ensure GTK also uses the correct cursor theme
    gtk = {
      enable = true;
      cursorTheme = {
        package = pkgs.capitaine-cursors;
        name = "capitaine-cursors";
        size = 24;
      };
    };

    # Enable Hyprland
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      systemd.enable = true;
      xwayland.enable = true;
      
      settings = {
        # Monitor configuration - adjust as needed
        monitor = [
          "eDP-1,1920x1200@60,0x0,1.0"  # 1x scale for maximum screen real estate
        ];

        # Ensure apps run natively on Wayland (Electron, Qt, GTK, etc.)
        # These env vars are applied to Hyprland and all child processes.
        env = [
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "NIXOS_OZONE_WL,1"
          "OZONE_PLATFORM_HINT,auto"
          "GTK_USE_PORTAL,1"
          "QT_QPA_PLATFORM,wayland;xcb"
          "MOZ_ENABLE_WAYLAND,1"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "SDL_VIDEODRIVER,wayland"
          "XCURSOR_THEME,capitaine-cursors"
          "XCURSOR_SIZE,24"
        ];

        # Input configuration - your keyboard mapping
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "caps:escape,altwin:swap_alt_win"; # Caps→Escape, Alt↔Super
          kb_rules = "";

          follow_mouse = 1;
          sensitivity = 0; # -1.0 - 1.0, 0 means no modification
          
          # Disable cursor warping when focusing windows - prevents wrapping behavior

          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-to-click = true;
          };
        };

        # Cursor configuration
        cursor = {
          default_monitor = "";
          zoom_factor = 1.0;
          zoom_rigid = false;
        };

        # General configuration
        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          "col.active_border" = "rgba(89b4faff) rgba(cba6f7ff) 45deg"; # Clean blue to purple gradient
          "col.inactive_border" = "rgba(313244ff)"; # Subtle gray
          layout = "dwindle"; # BSP-like layout
          allow_tearing = false;
        };

        # Decoration settings
        decoration = {
          rounding = 12;
          
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            new_optimizations = true;
          };
        };

        # Miscellaneous behavior tweaks
        misc = {
          disable_hyprland_logo = true;       # no splash/logo
          disable_splash_rendering = true;
          focus_on_activate = true;
          # Force new windows to open on current workspace, not last active
          new_window_takes_over_fullscreen = 0;
          initial_workspace_tracking = 1;
        };

        # Disable on-screen debug/error overlay at the top-left
        debug = {
          overlay = false;
        };

        # Animation configuration
        animations = {
          enabled = false; # Disabled per user preference
        };

        # Layout configuration (dwindle = BSP-like)
        dwindle = {
          pseudotile = true;
          preserve_split = true;
          smart_split = false;
          smart_resizing = false;
        };

        # Window rules for application-specific behavior (v2 syntax)
        windowrulev2 = [
          # Float certain applications
          "float,class:^(pavucontrol)$"
          "float,class:^(rofi)$"
          "float,class:^(wlogout)$"
          
          # Default floating window size and center position
          "size 800 600,floating:1"
          "center,floating:1"
          
          # Removed kitty opacity rule - now handled dynamically by kitty itself
        ];

        # Key bindings - replicating your skhd configuration exactly
        bind = [
          # Window focus (matching skhd cmd+hjkl -> Super+hjkl after key swap)
          "SUPER, h, movefocus, l"
          "SUPER, j, movefocus, d"
          "SUPER, k, movefocus, u"
          "SUPER, l, movefocus, r"

          # Window movement (matching skhd cmd+shift+hjkl)
          "SUPER_SHIFT, h, movewindow, l"
          "SUPER_SHIFT, j, movewindow, d"
          "SUPER_SHIFT, k, movewindow, u"
          "SUPER_SHIFT, l, movewindow, r"

          # Workspace switching (matching skhd cmd+1-9)
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"

          # Move window to workspace (matching skhd cmd+shift+1-9)
          "SUPER_SHIFT, 1, movetoworkspace, 1"
          "SUPER_SHIFT, 2, movetoworkspace, 2"
          "SUPER_SHIFT, 3, movetoworkspace, 3"
          "SUPER_SHIFT, 4, movetoworkspace, 4"
          "SUPER_SHIFT, 5, movetoworkspace, 5"
          "SUPER_SHIFT, 6, movetoworkspace, 6"
          "SUPER_SHIFT, 7, movetoworkspace, 7"
          "SUPER_SHIFT, 8, movetoworkspace, 8"
          "SUPER_SHIFT, 9, movetoworkspace, 9"

          # Workspace navigation (matching skhd cmd+ctrl+h/l)
          "SUPER_CTRL, h, workspace, e-1"
          "SUPER_CTRL, l, workspace, e+1"

          # Window management (matching skhd)
          "SUPER_SHIFT, q, killactive"        # Close window
          "SUPER, f, fullscreen, 0"           # Fullscreen toggle
          "SUPER, m, fullscreen, 1"           # Maximize toggle

          # Float toggle - creates a centered floating window
          "SUPER, t, togglefloating"

          # Terminal launcher
          "SUPER, Return, exec, ${config.djh.hyprland.terminal}"

          # Application launcher (Spotlight-like)
          "SUPER, space, exec, rofi -show drun"

          # Recent workspace (matching skhd alt+tab)
          "ALT, Tab, workspace, previous"

          # Simple resize bindings (Super + uiop)
          "SUPER, u, resizeactive, -50 0"      # Shrink width (left)
          "SUPER, p, resizeactive, 50 0"       # Expand width (right) 
          "SUPER, o, resizeactive, 0 -50"      # Shrink height (up)
          "SUPER, i, resizeactive, 0 50"       # Expand height (down)

          # Direct resize bindings (Super + Shift + arrow keys)
          "SUPER_SHIFT, Left, resizeactive, -50 0"
          "SUPER_SHIFT, Right, resizeactive, 50 0"
          "SUPER_SHIFT, Up, resizeactive, 0 -50"
          "SUPER_SHIFT, Down, resizeactive, 0 50"

          # Browser launcher (default Firefox)
          "SUPER, b, exec, firefox"

          # Zen browser specific keybindings - tab navigation
          "CTRL, j, exec, ${pkgs.writeShellScript "zen-ctrl-j" ''
            if hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class' | grep -q '^zen$'; then
              ${pkgs.wtype}/bin/wtype -M ctrl -P Tab -m ctrl
            fi
          ''}"
          "CTRL, k, exec, ${pkgs.writeShellScript "zen-ctrl-k" ''
            if hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class' | grep -q '^zen$'; then
              ${pkgs.wtype}/bin/wtype -M ctrl -M shift -P Tab -m shift -m ctrl
            fi
          ''}"

          # Screenshot
          "SUPER, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
          
          # System controls
          "SUPER, Delete, exec, wlogout"
          
          # Toggle waybar visibility
          "SUPER_SHIFT, f, exec, pkill -SIGUSR1 waybar"
        ];

        # Mouse bindings
        bindm = [
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizewindow"
        ];

        # Media keys
        bindl = [
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
          ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
        ];

        # Startup applications
        exec-once = [
          "waybar"
          "dunst"
          # Force set cursor theme to capitaine-cursors
          "hyprctl setcursor capitaine-cursors 24"
          # Download and set wallpaper
          "${config.home.homeDirectory}/.config/home-manager/scripts/setup-wallpaper.sh"
          "${config.djh.hyprland.terminal}" # Start terminal on workspace 3
        ];
      };
      
      # Additional configuration from user
      extraConfig = config.djh.hyprland.extraConfig;
    };

    # Configure supporting applications
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "battery" "tray" ];

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
            sort-by-number = true;
          };

          "hyprland/window" = {
            format = "{title}";
            max-length = 50;
          };

          clock = {
            format = "{:%Y-%m-%d %H:%M}";
            tooltip-format = "{:%Y-%m-%d | %H:%M:%S}";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "🔇";
            format-icons = [ "🔈" "🔉" "🔊" ];
            on-click = "pavucontrol";
          };

          network = {
            format-wifi = "📶 {essid}";
            format-ethernet = "🌐 {ifname}";
            format-disconnected = "❌";
            tooltip-format = "{ipaddr}/{cidr}";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-icons = [ "🔋" "🔋" "🔋" "🔋" "🔋" ];
            format-charging = "🔌 {capacity}%";
          };

          tray = {
            icon-size = 21;
            spacing = 10;
          };
        };
      };
      style = ''
        * {
          font-family: "JetBrains Mono", "Symbols Nerd Font", monospace;
          font-size: 13px;
          font-weight: 500;
          min-height: 0;
        }
        
        window#waybar {
          background: rgba(17, 17, 27, 0.8);
          color: #cdd6f4;
          border: 2px solid rgba(137, 180, 250, 0.3);
          border-radius: 12px;
          margin: 8px 8px 0px 8px;
          padding: 0px;
        }
        
        #workspaces {
          background: rgba(30, 30, 46, 0.4);
          margin: 4px 8px;
          border-radius: 8px;
          padding: 2px;
        }
        
        #workspaces button {
          padding: 6px 12px;
          background: transparent;
          color: #6c7086;
          border-radius: 6px;
          margin: 2px;
          transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
        }
        
        #workspaces button.active {
          color: #11111b;
          background: linear-gradient(45deg, #89b4fa, #cba6f7);
          box-shadow: 0 2px 8px rgba(137, 180, 250, 0.3);
        }
        
        #workspaces button:hover {
          background: rgba(137, 180, 250, 0.15);
          color: #89b4fa;
        }

        #window {
          background: rgba(30, 30, 46, 0.4);
          color: #f38ba8;
          font-weight: 600;
          margin: 4px 8px;
          padding: 8px 16px;
          border-radius: 8px;
        }

        #clock {
          background: rgba(30, 30, 46, 0.4);
          color: #94e2d5;
          font-weight: 600;
          margin: 4px 8px;
          padding: 8px 16px;
          border-radius: 8px;
        }

        #pulseaudio, #network, #battery {
          background: rgba(30, 30, 46, 0.4);
          padding: 8px 12px;
          margin: 4px 4px;
          border-radius: 8px;
          color: #a6e3a1;
          font-weight: 500;
        }

        #tray {
          background: rgba(30, 30, 46, 0.4);
          padding: 8px 12px;
          margin: 4px 8px;
          border-radius: 8px;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: rgba(251, 73, 52, 0.3);
        }
      '';
    };

    # Configure rofi
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      theme = "Arc-Dark";
      extraConfig = {
        modi = "drun,run,window";
        show-icons = true;
        drun-display-format = "{name}";
        disable-history = false;
        sidebar-mode = false;
        font = "JetBrains Mono 12";
        width = 600;
        height = 400;
        location = 0;
        xoffset = 0;
        yoffset = 0;
        columns = 1;
        fixed-num-lines = true;
        hide-scrollbar = true;
        terminal = "kitty";
        ssh-client = "ssh";
        ssh-command = "{terminal} -e {ssh-client} {host}";
        run-command = "{cmd}";
        run-list-command = "";
        run-shell-command = "{terminal} -e {cmd}";
        window-command = "xkill -id {window}";
        drun-match-fields = "name,generic,exec,categories";
        drun-categories = "";
        window-match-fields = "all";
        icon-theme = "Papirus-Dark";
        application-fallback-icon = "";
      };
    };

    # Enable necessary services
    services.dunst = {
      enable = true;
      settings = {
        global = {
          font = "FiraCode Nerd Font 11";
          allow_markup = true;
          format = "<b>%s</b>\\n%b";
          sort = true;
          indicate_hidden = true;
          alignment = "left";
          bounce_freq = 0;
          show_age_threshold = 60;
          word_wrap = true;
          ignore_newline = false;
          geometry = "300x5-30+20";
          idle_threshold = 120;
          monitor = 0;
          follow = "mouse";
          sticky_history = true;
          history_length = 20;
          show_indicators = true;
          line_height = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          separator_color = "frame";
          startup_notification = false;
          dmenu = "${pkgs.rofi-wayland}/bin/rofi -dmenu -p dunst:";
          browser = "zen-browser";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          corner_radius = 8;
        };
        urgency_low = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          timeout = 10;
        };
        urgency_normal = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          timeout = 10;
        };
        urgency_critical = {
          background = "#1e1e2e";
          foreground = "#f38ba8";
          frame_color = "#f38ba8";
          timeout = 0;
        };
      };
    };
  };
}
