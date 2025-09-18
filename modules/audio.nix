{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    djh.audio = {
      enable = mkEnableOption "Enhanced audio configuration with browser microphone support";
    };
  };

  config = mkIf config.djh.audio.enable {
    # Audio packages for better browser integration
    home.packages = with pkgs; [
      # PipeWire audio tools
      pipewire
      wireplumber
      
      # PulseAudio compatibility layer for browsers
      pulseaudio  # Provides pactl and compatibility
      
      # Audio control and monitoring
      pavucontrol      # GUI audio control
      helvum          # PipeWire patchbay GUI
      easyeffects     # Audio effects and processing
      
      # WebRTC and browser audio support
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-vaapi
    ];

    # XDG portal configuration for screen sharing and audio
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
          "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
          "org.freedesktop.impl.portal.Camera" = ["gtk"];
          "org.freedesktop.impl.portal.Microphone" = ["gtk"];
        };
        hyprland = {
          default = ["gtk" "hyprland"];
        };
      };
    };

    # Session variables for better browser audio
    home.sessionVariables = {
      # PipeWire configuration
      PIPEWIRE_LATENCY = "128/48000";
      
      # WebRTC configuration for browsers
      WEBRTC_USE_PIPEWIRE = "1";
      
      # GStreamer configuration
      GST_PLUGIN_SYSTEM_PATH_1_0 = "${pkgs.gst_all_1.gstreamer.out}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-ugly}/lib/gstreamer-1.0";
    };

    # PipeWire configuration files
    home.file = {
      # Client configuration for better browser compatibility
      ".config/pipewire/client.conf".text = ''
        context.properties = {
          log.level = 2
          default.clock.rate = 48000
          default.clock.quantum = 1024
          default.clock.min-quantum = 32
          default.clock.max-quantum = 2048
        }
        
        context.modules = [
          {
            name = libpipewire-module-rtkit
            args = {
              nice.level   = -11
              rt.prio      = 88
              rt.time.soft = 200000
              rt.time.hard = 200000
            }
            flags = [ ifexists nofail ]
          }
          { name = libpipewire-module-protocol-native }
          { name = libpipewire-module-client-node }
          { name = libpipewire-module-adapter }
          { name = libpipewire-module-metadata }
          {
            name = libpipewire-module-protocol-pulse
            args = {
              pulse.min.req = 32/48000
              pulse.default.req = 960/48000
              pulse.max.req = 8192/48000
              pulse.min.quantum = 32/48000
              pulse.max.quantum = 8192/48000
              server.address = [ "unix:native" ]
            }
          }
        ]
      '';
      
      # PipeWire daemon configuration
      ".config/pipewire/pipewire.conf".text = ''
        context.properties = {
          default.clock.rate = 48000
          default.clock.quantum = 1024
          default.clock.min-quantum = 32
          default.clock.max-quantum = 8192
          default.video.width = 640
          default.video.height = 480
          default.video.rate.num = 25
          default.video.rate.denom = 1
        }
        
        context.spa-libs = {
          audio.convert.* = audioconvert/libspa-audioconvert
          audio.mix.* = audiomixer/libspa-audiomixer
          api.alsa.* = alsa/libspa-alsa
          api.v4l2.* = v4l2/libspa-v4l2
          api.libcamera.* = libcamera/libspa-libcamera
          support.* = support/libspa-support
        }
        
        context.modules = [
          { name = libpipewire-module-rtkit }
          { name = libpipewire-module-protocol-native }
          { name = libpipewire-module-profiler }
          { name = libpipewire-module-metadata }
          { name = libpipewire-module-spa-device-factory }
          { name = libpipewire-module-spa-node-factory }
          { name = libpipewire-module-client-node }
          { name = libpipewire-module-client-device }
          { name = libpipewire-module-portal }
          { name = libpipewire-module-access }
          { name = libpipewire-module-adapter }
          { name = libpipewire-module-link-factory }
          { name = libpipewire-module-session-manager }
        ]
        
        context.objects = [
          { factory = spa-node-factory   args = { factory.name = support.node.driver node.name = Dummy driver = true } }
          { factory = spa-device-factory args = { factory.name = api.alsa.enum.udev } }
          { factory = spa-device-factory args = { factory.name = api.v4l2.enum.udev } }
          { factory = spa-device-factory args = { factory.name = api.libcamera.enum.manager } }
          { factory = adapter            args = { factory.name = audiotestsrc node.name = my-sample } }
          { factory = spa-node-factory   args = { factory.name = api.alsa.acp.device } }
        ]
        
        context.exec = [
          { path = "pactl" args = "upload-sample /usr/share/sounds/alsa/Front_Left.wav my-sample" }
        ]
      '';
    };

    # Services for audio support
    services = {
      # Enable PipeWire (should already be running, but ensure it's configured)
      # Note: PipeWire is typically started by the system, not user services
      
      # Enable EasyEffects for audio processing
      easyeffects.enable = true;
    };

    # Firefox-specific configuration for microphone access
    programs.firefox = mkIf (hasAttr "firefox" config.programs && config.programs.firefox.enable) {
      profiles = mkDefault {
        default = {
          settings = {
            # Enable WebRTC and microphone access
            "media.navigator.enabled" = true;
            "media.navigator.permission.disabled" = false;
            "media.peerconnection.enabled" = true;
            "media.peerconnection.use_document_iceservers" = true;
            "media.peerconnection.identity.enabled" = true;
            "media.peerconnection.dtls.enabled" = true;
            "media.peerconnection.video.enabled" = true;
            "media.getusermedia.screensharing.enabled" = true;
            "media.getusermedia.browser.enabled" = true;
            "media.getusermedia.audiocapture.enabled" = true;
            
            # PipeWire integration
            "media.cubeb.backend" = "pulse";
            "media.cubeb.output_voice_routing" = true;
            "media.autoplay.blocking_policy" = 0;
            
            # Privacy settings that don't block functionality
            "privacy.webrtc.hide_default_local_ips_behind_proxies" = false;
            "privacy.webrtc.legacy.allow_loopback_in_peer_connection" = true;
          };
        };
      };
    };

    # Desktop entries for audio tools
    xdg.desktopEntries = {
      audio-control = {
        name = "Audio Control Center";
        comment = "Comprehensive audio control with PipeWire tools";
        exec = "${pkgs.pavucontrol}/bin/pavucontrol";
        icon = "multimedia-volume-control";
        categories = [ "AudioVideo" "Settings" ];
        type = "Application";
      };
      
      pipewire-graph = {
        name = "PipeWire Graph";
        comment = "Visual PipeWire audio routing";
        exec = "${pkgs.helvum}/bin/helvum";
        icon = "multimedia-volume-control";
        categories = [ "AudioVideo" "Settings" ];
        type = "Application";
      };
    };
  };
}
