{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.chromium = {
    enable = mkEnableOption "Chromium browser with WebRTC and microphone support";
  };

  config = mkIf config.djh.chromium.enable {
    # Chromium browser configuration
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;
    };

    # Environment variables for WebRTC and audio
    home.sessionVariables = {
      # WebRTC PipeWire support (already set in audio module, but ensure it's here too)
      WEBRTC_USE_PIPEWIRE = "1";
      # Enable PulseAudio in Chromium
      PULSE_PROP_media_role = "phone";
    };

    # Additional Chromium preferences via environment
    programs.chromium.commandLineArgs = [
      # Enable WebRTC audio/video input
      "--enable-webrtc"
      # Use PipeWire for audio
      "--use-cras"
      # Enable audio input
      "--enable-audio-input-permissions"
      # Disable sandbox for audio input (required for proper microphone access)
      "--disable-setuid-sandbox"
    ];
  };
}
