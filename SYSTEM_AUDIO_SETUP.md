# System Audio Configuration for Hyprland

## Required System Configuration

Add this to your NixOS system configuration (/etc/nixos/configuration.nix):

```nix
# Audio configuration - system level (REQUIRED)
hardware.pulseaudio.enable = false;  # Disable old PulseAudio
security.rtkit.enable = true;        # Real-time audio scheduling

services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;  # PulseAudio compatibility for browsers/apps
  jack.enable = true;   # JACK compatibility (optional)
  
  # Stable configuration
  wireplumber.enable = true;
};

# User permissions for audio devices
users.users.djh.extraGroups = [ "audio" ];

# XDG portals for Hyprland screen sharing/audio (system level)
xdg.portal = {
  enable = true;
  wlr.enable = true;
  extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
};
```

## What this provides:
- **System-managed PipeWire** (much more reliable than user services)
- **Automatic hardware detection** and configuration  
- **PulseAudio compatibility** for browsers and legacy applications
- **Real-time scheduling** for low-latency audio
- **Proper permissions** for audio device access
- **XDG portals** for screen sharing with audio in browsers

## After Configuration:
1. Run `sudo nixos-rebuild switch`
2. Reboot your system for clean audio service startup
3. Run `home-manager switch` to apply the new user-space configuration

## Troubleshooting:
- Check audio status: `wpctl status`
- List devices: `wpctl inspect @DEFAULT_AUDIO_SINK@`
- Test microphone: `wpctl inspect @DEFAULT_AUDIO_SOURCE@`
- Browser permissions: Check site-specific microphone permissions
