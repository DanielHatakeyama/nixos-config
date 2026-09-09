{ pkgs, ... }:

with pkgs; 

let
  # Create a wrapper for nix-shell that uses zsh by default
  nix-shell-zsh = pkgs.writeShellScriptBin "nix-shell-zsh" ''
    # Start nix-shell with bash for setup, then switch to zsh
    exec bash -c "exec $(command -v nix-shell) \"\$@\" --run '${pkgs.zsh}/bin/zsh'" -- "$@"
  '';
  
  # Create a wrapper for Steam that forces X11 for UI stability
  # This allows Steam UI to render properly while games still use Wayland when available
  # steam-wrapper = pkgs.writeShellScriptBin "steam-x11" ''
  #   # Force SDL to try X11 with Wayland fallback (more stable for Steam UI)
  #   export SDL_VIDEODRIVER="x11,wayland"
  #   export DISPLAY=":0"
  #   export QT_QPA_PLATFORM="xcb"
  #
  #   # Prevent Wayland-only initialization
  #   unset WAYLAND_DISPLAY
  #
  #   # Make sure X11 libraries are available
  #   export LD_LIBRARY_PATH="${pkgs.xorg.libX11}/lib:${pkgs.xorg.libxcb}/lib:$LD_LIBRARY_PATH"
  #
  #   exec ${pkgs.steam}/bin/steam "$@"
  # '';

  # Audio sink switcher for easy device selection
  audio-switch = pkgs.writeShellScriptBin "audio-switch" ''
    #!/bin/bash
    
    # List all available audio sinks
    echo "Available audio outputs:"
    pactl list short sinks | nl
    
    if [ -z "$1" ]; then
      echo ""
      echo "Usage: audio-switch <number>"
      echo "Example: audio-switch 1  (to switch to first sink)"
      echo ""
      echo "Or use fzf to select interactively:"
      echo "pactl list short sinks | fzf | awk '{print \$1}' | xargs -I {} pactl set-default-sink {}"
      exit 1
    fi
    
    # Get sink number from argument
    SINK=$(pactl list short sinks | sed -n "$1p" | awk '{print $1}')
    
    if [ -z "$SINK" ]; then
      echo "Error: Invalid sink number"
      exit 1
    fi
    
    # Switch to the selected sink
    pactl set-default-sink "$SINK"
    
    # Show confirmation
    NEW_SINK=$(pactl get-default-sink)
    echo "Switched to: $NEW_SINK"
  '';
  
  # Vim-friendly CLI app launcher with fzf
  # Works like: app-launcher [search-term]
  # Or interactively: app-launcher
  app-launcher = pkgs.writeShellScriptBin "app-launcher" ''
    #!/bin/bash
    
    # Get all available applications from .desktop files
    get_apps() {
      find ~/.local/share/applications /usr/share/applications -name "*.desktop" 2>/dev/null | \
        while read f; do
          grep "^Name=" "$f" | cut -d'=' -f2 | head -1
        done | sort -u
    }
    
    # If search term provided, filter and launch first match
    if [ -n "$1" ]; then
      app=$(get_apps | grep -i "$1" | head -1)
      if [ -z "$app" ]; then
        echo "❌ No app found matching: $1"
        echo ""
        echo "Available apps:"
        get_apps | head -20
        exit 1
      fi
      # Find and launch the .desktop file
      desktop_file=$(find ~/.local/share/applications /usr/share/applications -name "*.desktop" 2>/dev/null | \
        while read f; do
          if grep -q "^Name=$app$" "$f"; then
            echo "$f"
            break
          fi
        done)
      if [ -n "$desktop_file" ]; then
        exec ${pkgs.gtk3}/bin/gtk-launch "$(basename "$desktop_file" .desktop)" 2>/dev/null &
      fi
    else
      # Interactive mode with fzf - Vim-like experience
      app=$(get_apps | ${pkgs.fzf}/bin/fzf \
        --preview 'echo {}' \
        --height 40% \
        --reverse \
        --border \
        --margin 1 \
        --padding 1 \
        --prompt "🔍 Apps > " \
        --bind "ctrl-l:clear-query" \
        --bind "ctrl-j:down,ctrl-k:up" \
        --preview-window "right:30%:wrap" \
        --color "fg:#ebdbb2,bg:#282828,hl:#fabd2f:bold" \
        --color "fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f:bold" \
        --color "info:#8ec07c,prompt:#fb4934,pointer:#fb4934" \
        --color "marker:#b8bb26,spinner:#fabd2f,header:#928374")
      
      if [ -z "$app" ]; then
        exit 0
      fi
      
      # Find and launch the .desktop file
      desktop_file=$(find ~/.local/share/applications /usr/share/applications -name "*.desktop" 2>/dev/null | \
        while read f; do
          if grep -q "^Name=$app$" "$f"; then
            echo "$f"
            break
          fi
        done)
      if [ -n "$desktop_file" ]; then
        exec ${pkgs.gtk3}/bin/gtk-launch "$(basename "$desktop_file" .desktop)" 2>/dev/null &
      else
        echo "❌ Could not find desktop file for: $app"
        exit 1
      fi
    fi
  '';
in

[

  xclip # Idk if i need this`
  vscode # Maybe make this a module idk, if i use the config i have might need to do that via a module 

  gcc
  gnumake
  pkg-config

  # Rusty Tools
  fzf
  ripgrep
  fd

  # Network tools
  nmap

  # Imperitive / Ad-Hoc Package Management
  appimage-run
  flatpak
  
  # Custom scripts
  nix-shell-zsh    # Wrapper to use zsh in nix-shell
  audio-switch     # Easy audio output switching tool
  app-launcher     # Vim-friendly app launcher with fzf

  # Programs profile login custimization
  discord
  obsidian
  tor-browser
  zoom-us          # Video conferencing with audio/microphone support
  prismlauncher    # Minecraft launcher with mod support (Fabric, Forge, Quilt)

  # VM - GNOME Boxes uses libvirt/KVM for Windows/Linux VMs
  gnome-boxes

  google-cloud-sdk # Google Cloud CLI (gcloud)
  
  # Containerization & Development
  docker           # Docker container runtime
  docker-compose   # Docker Compose for multi-container apps
  docker-buildx    # Docker Buildx for advanced builds
  
  # Rust Development
  rustc            # Rust compiler
  cargo            # Rust package manager
  rustfmt          # Rust code formatter
  clippy           # Rust linter
  rust-analyzer    # Rust LSP server for IDE support
  
  # Development Environment Tools
  direnv           # Per-directory environment variables
  nix-direnv       # Fast direnv integration with Nix
]
