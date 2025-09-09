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
    ];

    # Enable Hyprland
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      systemd.enable = true;
      xwayland.enable = true;
      
      settings = {
        # Monitor configuration - adjust as needed
        monitor = [
          ",preferred,auto,auto"
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

          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-to-click = true;
          };
        };

        # General configuration
        general = {
          gaps_in = config.djh.hyprland.gaps;
          gaps_out = config.djh.hyprland.gaps * 2;
          border_size = config.djh.hyprland.borderSize;
          "col.active_border" = "rgba(cba6f7ff) rgba(89b4faff) 45deg"; # Catppuccin purple/blue
          "col.inactive_border" = "rgba(585b70ff)"; # Catppuccin surface2
          layout = "dwindle"; # BSP-like layout
          allow_tearing = false;
        };

        # Decoration settings
        decoration = {
          rounding = 8;
          
          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            new_optimizations = true;
          };

          drop_shadow = true;
          shadow_range = 4;
          shadow_render_power = 3;
          "col.shadow" = "rgba(1a1a1aee)";
        };

        # Animation configuration
        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        # Layout configuration (dwindle = BSP-like)
        dwindle = {
          pseudotile = true;
          preserve_split = true;
          smart_split = false;
          smart_resizing = false;
        };

        # Window rules for application-specific behavior
        windowrule = [
          # VS Code / Cursor -> workspace 1 (code)
          "workspace 1 silent,^(code)$"
          "workspace 1 silent,^(cursor)$"
          
          # Browser -> workspace 2 (browser)  
          "workspace 2 silent,^(zen-browser)$"
          "workspace 2 silent,^(firefox)$"
          "workspace 2 silent,^(torbrowser)$"
          
          # Terminal -> workspace 3 (terminal)
          "workspace 3 silent,^(kitty)$"
          "workspace 3 silent,^(org.gnome.Console)$"
          
          # Chat -> workspace 4 (chat)
          "workspace 4 silent,^(discord)$"
          "workspace 4 silent,^(slack)$"
          
          # Float certain applications
          "float,^(pavucontrol)$"
          "float,^(rofi)$"
          "float,^(wlogout)$"
          
          # Opacity rules (matching yabai)
          "opacity 0.9 0.9,^(kitty)$"
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

          # Float toggle (matching skhd alt+f)
          "ALT, f, togglefloating"
          "ALT, f, centerwindow"

          # Terminal launcher
          "SUPER, Return, exec, ${config.djh.hyprland.terminal}"

          # Application launcher
          "ALT, r, exec, rofi -show drun"

          # Recent workspace (matching skhd alt+tab)
          "ALT, Tab, workspace, previous"

          # Modal systems (matching skhd exactly)
          "ALT, r, exec, ${config.home.homeDirectory}/.config/home-manager/scripts/hyprland-window-manager.sh resize-mode"
          "ALT, p, exec, ${config.home.homeDirectory}/.config/home-manager/scripts/hyprland-window-manager.sh resize-mode" 
          "ALT, w, exec, ${config.home.homeDirectory}/.config/home-manager/scripts/hyprland-window-manager.sh wasd-mode"

          # Screenshot
          "SUPER, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
          
          # System controls
          "SUPER, Escape, exec, wlogout"
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
          "hyprpaper"
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
          font-family: "FiraCode Nerd Font", monospace;
          font-size: 13px;
        }
        
        window#waybar {
          background-color: rgba(30, 30, 46, 0.9);
          color: #cdd6f4;
          border-bottom: 3px solid rgba(203, 166, 247, 0.8);
        }
        
        #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #6c7086;
          border-radius: 0;
        }
        
        #workspaces button.active {
          color: #cba6f7;
          background-color: rgba(203, 166, 247, 0.2);
        }
        
        #workspaces button:hover {
          background-color: rgba(203, 166, 247, 0.1);
          color: #cba6f7;
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
