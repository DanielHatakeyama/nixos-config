{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    djh.audio = {
      enable = mkEnableOption "Simple and stable audio configuration for Google Meet and Zen Browser";
    };
  };
  config = mkIf config.djh.audio.enable {
    # Keep things as close to a stock NixOS install as possible:
    # rely on the system PipeWire setup and only ship the basic
    # mixer GUI so the user can adjust volumes.
    home.packages = with pkgs; [ pavucontrol ];

    home.sessionVariables = {
      WEBRTC_USE_PIPEWIRE = "1";
      PULSE_PROP_media_role = "phone";
    };

    # HM-only mitigation for sof-hda-dsp ALSA "Broken pipe" recover loops.
    #
    # Based on live cutout snapshots:
    # - ARC Raiders streams remain active and routed correctly
    # - sink remains RUNNING
    # - PipeWire logs repeated: spa.alsa: hw:sofhdadspp: snd_pcm_avail after recover: Broken pipe
    #
    # These drop-ins try to reduce device state churn and keep timing fixed.
    # They are deliberately small and easy to revert.

    # Force a stable clock rate/quantum (your current session already shows 48k/1024).
    # We force these to avoid renegotiation and to keep the graph consistent.
    xdg.configFile."pipewire/pipewire.conf.d/90-hm-sof-stability.conf".text = ''
      context.properties = {
        default.clock.rate = 48000
        default.clock.allowed-rates = [ 48000 ]
        default.clock.quantum = 1024
        default.clock.min-quantum = 1024
        default.clock.max-quantum = 1024
        default.clock.force-rate = 48000
        default.clock.force-quantum = 1024
      }
    '';

    # Disable suspend on ALSA nodes. Even though sinks showed RUNNING during cutout,
    # on some SOF setups background policy/power transitions can still contribute.
    xdg.configFile."wireplumber/wireplumber.conf.d/90-hm-disable-alsa-suspend.conf".text = ''
      monitor.alsa.rules = [
        {
          matches = [ { node.name = "alsa_*" } ]
          actions = {
            update-props = {
              session.suspend-timeout-seconds = 0
            }
          }
        }
      ]
    '';
  };
}
