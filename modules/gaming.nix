{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    djh.gaming = {
      enable = mkEnableOption "Gaming applications and configuration";
      
      enableSteam = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam gaming platform";
      };
      
      enableMinecraft = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Minecraft with PrismLauncher";
      };
    };
  };

  config = mkIf config.djh.gaming.enable {
    # Gaming packages with authentication dependencies
    home.packages = with pkgs; [
      # Core gaming applications
      (mkIf config.djh.gaming.enableSteam steam)
      (mkIf config.djh.gaming.enableMinecraft prismlauncher)
      
      # Authentication and web support dependencies
      webkitgtk_4_1     # For embedded browsers in launchers (Microsoft auth)
      xdg-utils         # For proper URL/browser handling
      libsecret         # For secure credential storage
      gnome-keyring     # Keyring for storing authentication tokens
      
      # Gaming utilities
      gamemode          # Performance optimization
      mangohud          # Performance overlay
    ];

    # Environment variables for better gaming authentication
    home.sessionVariables = {
      # Enable proper browser integration for authentication
      XDG_CURRENT_DESKTOP = "Hyprland";
      
      # Java environment for Minecraft authentication
      _JAVA_OPTIONS = "-Djava.net.useSystemProxies=true -Djavafx.platform=gtk";
      
      # Steam environment for better compatibility
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${config.home.homeDirectory}/.steam/root/compatibilitytools.d";
    };

    # XDG configuration for proper application handling
    xdg = {
      enable = true;
      
      # Ensure proper MIME type handling for authentication redirects
      mimeApps = {
        enable = true;
        associations.added = {
          "x-scheme-handler/minecraft" = ["org.prismlauncher.PrismLauncher.desktop"];
          "application/x-java-archive" = ["org.prismlauncher.PrismLauncher.desktop"];
        };
      };
      
      # Desktop entries with proper authentication support
      desktopEntries = mkIf config.djh.gaming.enableMinecraft {
        minecraft-auth = {
          name = "Minecraft (Enhanced Auth)";
          comment = "Minecraft launcher with enhanced Microsoft authentication";
          exec = "${pkgs.prismlauncher}/bin/prismlauncher --java-args=\"-Djava.net.useSystemProxies=true -Djavafx.platform=gtk\"";
          icon = "prismlauncher";
          categories = [ "Game" "AdventureGame" ];
          type = "Application";
          settings = {
            StartupNotify = "true";
            StartupWMClass = "PrismLauncher";
          };
        };
      };
    };

    # Services for gaming support
    services = {
      # Enable gnome-keyring for secure credential storage
      gnome-keyring = {
        enable = true;
        components = [ "secrets" "ssh" ];
      };
    };

    # Systemd user services for gaming optimization
    systemd.user.services = mkIf config.djh.gaming.enableSteam {
      gamemode = {
        Unit = {
          Description = "GameMode performance daemon";
          Documentation = "man:gamemoded(8)";
        };
        Service = {
          Type = "dbus";
          BusName = "com.feralinteractive.GameMode";
          ExecStart = "${pkgs.gamemode}/bin/gamemoded";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };

    # Configuration files for gaming applications
    home.file = {
      # GameMode configuration for optimal performance
      ".config/gamemode.ini".text = ''
        [general]
        renice=10
        ioprio=4
        inhibit_screensaver=1
        
        [filter]
        whitelist=steam
        whitelist=prismlauncher
        whitelist=minecraft
        whitelist=java
        
        [custom]
        start=notify-send "GameMode" "Performance mode activated" --expire-time=2000
        end=notify-send "GameMode" "Performance mode deactivated" --expire-time=2000
      '';
      
      # MangoHud configuration for performance monitoring
      ".config/MangoHud/MangoHud.conf".text = ''
        fps
        frametime
        cpu_temp
        gpu_temp
        ram
        position=top-left
        font_size=16
        alpha=0.8
        background_alpha=0.4
        round_corners=5
        
        toggle_fps_limit=F1
        fps_limit=144,60,30
      '';
    };

    # Fonts needed for proper game rendering and UI
    fonts.fontconfig.enable = true;
  };
}
