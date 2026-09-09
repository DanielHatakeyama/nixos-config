# Direnv & Nix-Shell with Zsh Configuration

## What Was Configured

### 1. ✅ Direnv Installation
- **direnv**: Automatically loads environment variables when you enter a directory
- **nix-direnv**: Fast, cached integration with Nix for instant environment loading

### 2. ✅ Nix-Shell with Zsh
- `NIX_BUILD_SHELL` set to zsh, so `nix-shell` uses your zsh/oh-my-zsh config
- No more plain bash when you enter nix-shell!

### 3. ✅ Integration
- Direnv plugin added to oh-my-zsh
- Full zsh integration enabled
- Automatic hook setup

## Activation

**Restart your shell:**
```bash
exec zsh
```

Or open a new terminal window.

## How to Use Direnv

### Basic Setup

**1. Create a `.envrc` file in your project directory:**

```bash
cd ~/my-project
echo 'use nix' > .envrc
```

**2. Allow direnv to load the file:**
```bash
direnv allow
```

Now whenever you `cd` into this directory, the Nix environment will automatically load!

### Example: Python Project with Nix

**Create a `shell.nix` file:**
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python311
    python311Packages.pip
    python311Packages.virtualenv
  ];
  
  shellHook = ''
    echo "Python development environment loaded!"
    python --version
  '';
}
```

**Create `.envrc`:**
```bash
use nix
```

**Allow and enter:**
```bash
direnv allow
cd .  # or just enter the directory
```

The environment loads automatically! 🎉

### Example: Rust Project

**shell.nix:**
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
  ];
}
```

**.envrc:**
```bash
use nix
```

### Example: Environment Variables

**.envrc:**
```bash
# Load Nix environment
use nix

# Set environment variables
export DATABASE_URL="postgresql://localhost/mydb"
export API_KEY="secret-key"
export DEBUG=true

# Add local bin to PATH
PATH_add ./bin
```

### Using Flakes

If you use Nix flakes:

**.envrc:**
```bash
use flake
```

Or with a specific flake output:
```bash
use flake .#devShell
```

## Nix-Shell with Zsh

Now when you run `nix-shell`, you'll get your full zsh environment:

```bash
nix-shell -p nodejs python311
# You're now in zsh with oh-my-zsh, not plain bash!
```

Your prompt, aliases, plugins, and completions all work! 🚀

## Common Direnv Commands

| Command | Description |
|---------|-------------|
| `direnv allow` | Allow direnv to load `.envrc` in current directory |
| `direnv deny` | Deny loading `.envrc` |
| `direnv reload` | Reload the environment |
| `direnv edit` | Edit `.envrc` with $EDITOR and auto-allow |
| `direnv status` | Show current direnv status |

## Pro Tips

### 1. **Instant Loading with nix-direnv**
The first time you enter a directory, it might take a moment to build. But subsequent entries are instant thanks to nix-direnv caching!

### 2. **Git Integration**
Add `.envrc` to your repository, but `.direnv/` should be in `.gitignore`:

```bash
echo '.direnv/' >> .gitignore
```

### 3. **Layout Commands**
Use built-in layouts in `.envrc`:

```bash
# Python virtualenv
layout python

# Ruby
layout ruby

# Node.js
layout node
```

### 4. **Combining Direnv with Flakes**
For the best experience:

```bash
# .envrc
use flake

# flake.nix
{
  description = "Development environment";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.nodejs pkgs.python311 ];
      };
    };
}
```

### 5. **Global .envrc (Home Directory)**
You can create a global `.envrc` in your home directory:

```bash
# ~/.envrc
export EDITOR=nvim
PATH_add ~/.local/bin
```

## Troubleshooting

### Direnv not loading?
```bash
# Check status
direnv status

# Reload manually
direnv reload

# Re-allow
direnv allow
```

### Environment variables not persisting?
Make sure you have `direnv allow` run in that directory.

### Want to see what direnv is doing?
```bash
# Enable debugging
export DIRENV_LOG_FORMAT=
```

## Quick Start Template

For any new project:

```bash
# 1. Create project directory
mkdir my-project && cd my-project

# 2. Create shell.nix
cat > shell.nix << 'EOF'
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Add your dependencies here
  ];
}
EOF

# 3. Create .envrc
echo 'use nix' > .envrc

# 4. Allow direnv
direnv allow

# 5. Done! The environment loads automatically when you enter this directory
```

## Benefits

✅ **Automatic Environment Loading** - No more `nix-shell` or `source venv/bin/activate`
✅ **Project Isolation** - Each project has its own environment
✅ **Fast** - nix-direnv caches environments for instant loading
✅ **Zsh in Nix-Shell** - Keep your shell configuration in nix-shell
✅ **Team Friendly** - Commit `.envrc` and `shell.nix` for reproducible environments

Enjoy your supercharged development workflow! 🚀
