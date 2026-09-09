{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    djh.audio = {
      enable = mkEnableOption "Stable audio configuration for system-managed PipeWire";
    };
  };

  config = mkIf config.djh.audio.enable {
    # Essential user-space audio tools only
    home.packages = with pkgs; [
      # Core audio control tools
      pavucontrol      # GUI volume/audio device control
      helvum          # PipeWire connection graph viewer
      
      # Audio enhancement (optional)
      easyeffects     # Audio effects and processing
      
      # Browser audio support (minimal)
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-vaapi
      
      # Utilities for troubleshooting
      alsa-utils      # aplay, amixer, etc.
      pulseaudio      # For pactl command
    ];

    # Minimal browser environment variables
    home.sessionVariables = {
      # Enable WebRTC to use PipeWire 
      WEBRTC_USE_PIPEWIRE = "1";
    };

    # Desktop entries for easy access
    xdg.desktopEntries = {
      pavucontrol = {
        name = "Volume Control";
        comment = "Adjust audio volume and devices";
        exec = "${pkgs.pavucontrol}/bin/pavucontrol";
        icon = "multimedia-volume-control";
        categories = [ "AudioVideo" "Settings" ];
        type = "Application";
      };
      
      helvum = {
        name = "Audio Connections";
        comment = "View and manage PipeWire audio connections";
        exec = "${pkgs.helvum}/bin/helvum";
        icon = "multimedia-volume-control";
        categories = [ "AudioVideo" "Settings" ];
        type = "Application";
      };
    };

    # Enable EasyEffects service for audio processing
    services.easyeffects.enable = true;

    # Browser configuration (only if browser programs are enabled)
    programs.firefox = mkIf (config.programs.firefox.enable or false) {
      profiles.default.settings = {
        # Essential WebRTC/microphone settings
        "media.navigator.enabled" = true;
        "media.getusermedia.audiocapture.enabled" = true;
        "media.peerconnection.enabled" = true;
        
        # Use PulseAudio compatibility layer
        "media.cubeb.backend" = "pulse";
      };
    };
    
    programs.chromium = mkIf (config.programs.chromium.enable or false) {
      commandLineArgs = [
        # Enable PipeWire for WebRTC
        "--enable-features=WebRTCPipeWireCapturer"
      ];
    };
  };
}
