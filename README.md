 Home Manager Configuration

This repository contains my personal Home Manager configuration for managing dotfiles and system packages across multiple systems using Nix.

## 🏗️ Structure

```
├── modules/           # Self-contained feature modules
│   ├── desktop-integration.nix  # Desktop file management
│   ├── gnome.nix     # GNOME desktop environment
│   ├── kitty.nix     # Kitty terminal with Nerd Fonts
│   ├── neovim.nix    # Neovim with LazyVim configuration
│   ├── tmux.nix      # Tmux with powerline theme
│   └── zen.nix       # Zen Browser
├── programs/         # Program-specific configurations
│   ├── git.nix       # Git configuration
│   ├── packages.nix  # System packages
│   ├── vscode.nix    # VS Code configuration
│   └── zsh.nix       # Zsh with Oh My Zsh
├── archive_config/   # Archived configurations from other systems
├── config/           # Additional configuration files
├── home.nix          # Main Home Manager configuration
├── flake.nix         # Nix flake configuration
└── README.md         # This file
```

## 🚀 Quick Start

### First Time Setup

1. Clone this repository:
   ```bash
   git clone <repository-url> ~/.config/home-manager
   cd ~/.config/home-manager
   ```

2. Install Home Manager (if not already installed):
   ```bash
   nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
   nix-channel --update
   nix-shell '<home-manager>' -A install
   ```

3. Apply the configuration:
   ```bash
   home-manager switch
   ```

### Regular Usage

- **Apply changes**: `home-manager switch`
- **Test configuration**: `home-manager build`
- **Check for issues**: `home-manager news`

## 📦 Enabled Modules

All modules can be toggled via the `djh.{module}.enable` options in `home.nix`:

- ✅ **Kitty Terminal** - With FiraCode Nerd Font and powerline symbols
- ✅ **Neovim** - LazyVim configuration with C compiler support
- ✅ **Tmux** - Session management with vim navigation
- ✅ **Zsh** - Oh My Zsh with useful plugins
- ✅ **Desktop Integration** - Automatic .desktop file management
- ✅ **GNOME** - Desktop environment tweaks
- ✅ **Zen Browser** - Privacy-focused browser

## 🛠️ Customization

### Adding New Modules

Create a new module in `modules/` following the pattern:

```nix
{ config, lib, pkgs, ... }:
with lib;
{
  options.djh.{module-name} = {
    enable = mkEnableOption "{Module description}";
  };
  
  config = mkIf config.djh.{module-name}.enable {
    # Module configuration here
  };
}
```

Then add it to `home.nix`:
```nix
imports = [ ./modules/{module-name}.nix ];
djh.{module-name}.enable = true;
```

### Managing Packages

Edit `programs/packages.nix` to add or remove system packages.

## 🖥️ Multi-System Support

This configuration is designed to work across different systems. System-specific tweaks can be added using:

```nix
lib.mkIf pkgs.stdenv.isLinux {
  # Linux-specific configuration
}

lib.mkIf pkgs.stdenv.isDarwin {
  # macOS-specific configuration  
}
```

## 🔧 Troubleshooting

### Desktop Integration Issues
If applications don't appear in the desktop environment:
```bash
nix-desktop-fix <application-name>
```

### Font Issues
If Nerd Font icons don't display properly in Kitty:
- The FiraCode Nerd Font is automatically installed with the kitty module
- Restart Kitty after applying changes

### Plugin Errors
If you see oh-my-zsh plugin errors, they're likely handled by Home Manager directly instead of oh-my-zsh plugins.

## 📝 License

This configuration is for personal use. Feel free to use it as inspiration for your own setup.

## 🤝 Contributing

This is a personal configuration repository, but feel free to open issues or suggest improvements!