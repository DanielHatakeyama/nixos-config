{ pkgs, ... }:

# FUTURE: Inline script derivations below (nix-shell-zsh, audio-switch, app-launcher)
# are band-aids. Each should eventually become its own module under modules/.
# See NORTH_STAR.md for the target architecture.

with pkgs;

let
  # Wrapper that starts nix-shell but drops into zsh instead of bash.
  nix-shell-zsh = pkgs.writeShellScriptBin "nix-shell-zsh" ''
    exec bash -c "exec $(command -v nix-shell) \"\$@\" --run '${pkgs.zsh}/bin/zsh'" -- "$@"
  '';

  # Interactive audio sink switcher.
  audio-switch = pkgs.writeShellScriptBin "audio-switch" ''
    echo "Available audio outputs:"
    pactl list short sinks | nl

    if [ -z "$1" ]; then
      echo ""
      echo "Usage: audio-switch <number>"
      exit 1
    fi

    SINK=$(pactl list short sinks | sed -n "$1p" | awk '{print $1}')

    if [ -z "$SINK" ]; then
      echo "Error: Invalid sink number"
      exit 1
    fi

    pactl set-default-sink "$SINK"
    echo "Switched to: $(pactl get-default-sink)"
  '';

  # fzf-based app launcher that reads from .desktop files.
  app-launcher = pkgs.writeShellScriptBin "app-launcher" ''
    get_apps() {
      find ~/.local/share/applications /usr/share/applications -name "*.desktop" 2>/dev/null | \
        while read f; do
          grep "^Name=" "$f" | cut -d'=' -f2 | head -1
        done | sort -u
    }

    if [ -n "$1" ]; then
      app=$(get_apps | grep -i "$1" | head -1)
      if [ -z "$app" ]; then
        echo "No app found matching: $1"
        exit 1
      fi
      desktop_file=$(find ~/.local/share/applications /usr/share/applications -name "*.desktop" 2>/dev/null | \
        while read f; do
          if grep -q "^Name=$app$" "$f"; then echo "$f"; break; fi
        done)
      [ -n "$desktop_file" ] && exec ${pkgs.gtk3}/bin/gtk-launch "$(basename "$desktop_file" .desktop)" 2>/dev/null &
    else
      app=$(get_apps | ${pkgs.fzf}/bin/fzf --height 40% --reverse --border --prompt "Apps > ")
      [ -z "$app" ] && exit 0
      desktop_file=$(find ~/.local/share/applications /usr/share/applications -name "*.desktop" 2>/dev/null | \
        while read f; do
          if grep -q "^Name=$app$" "$f"; then echo "$f"; break; fi
        done)
      if [ -n "$desktop_file" ]; then
        exec ${pkgs.gtk3}/bin/gtk-launch "$(basename "$desktop_file" .desktop)" 2>/dev/null &
      else
        echo "Could not find desktop file for: $app"
        exit 1
      fi
    fi
  '';
in

[
  vscode

  # Build tools
  gcc
  gnumake
  pkg-config

  # CLI search tools
  fzf
  ripgrep
  fd

  # Network tools
  nmap

  # Imperative / ad-hoc package management
  appimage-run
  flatpak

  # Custom scripts (see FUTURE note at top)
  nix-shell-zsh
  audio-switch
  app-launcher

  # Applications
  discord
  obsidian
  tor-browser
  zoom-us
  prismlauncher

  # Virtualization
  gnome-boxes

  # Cloud / infrastructure
  google-cloud-sdk

  # Containerization
  docker
  docker-compose
  docker-buildx

  # Rust development
  rustc
  cargo
  rustfmt
  clippy
  rust-analyzer
]
