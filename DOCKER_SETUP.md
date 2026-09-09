# Docker Setup on NixOS

## What Was Added

I've added the following Docker tools to your home-manager packages:
- `docker` - Docker container runtime and CLI
- `docker-compose` - Tool for defining and running multi-container applications
- `docker-buildx` - Docker CLI plugin for extended build capabilities

## ⚠️ Important: System-Level Configuration Required

For Docker to work on NixOS, you need **system-level configuration** in addition to the packages. The Docker daemon requires root privileges and systemd services.

### Option 1: Using Docker (Recommended for NixOS)

Add this to your `/etc/nixos/configuration.nix`:

```nix
{
  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;  # Start Docker daemon on boot
  };
  
  # Add your user to the docker group
  users.users.djh.extraGroups = [ "docker" ];
}
```

Then rebuild your system:
```bash
sudo nixos-rebuild switch
```

After rebuilding, log out and back in for group changes to take effect.

### Option 2: Using Podman (Docker-compatible alternative)

Podman is a daemonless container engine that's more "Nix-friendly":

```nix
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # Create 'docker' alias for podman
    defaultNetwork.settings.dns_enabled = true;
  };
  
  users.users.djh.extraGroups = [ "podman" ];
}
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

## Verification

After setting up Docker at the system level:

```bash
# Check Docker version
docker --version

# Check Docker daemon is running
systemctl status docker

# Test Docker
docker run hello-world

# Check Docker Compose
docker-compose --version

# Check your user is in docker group
groups | grep docker
```

## Docker Desktop

**Note**: Docker Desktop is not directly available on NixOS through nixpkgs. However, you have alternatives:

### Alternative 1: Use Docker CLI + Portainer (Web UI)
```nix
# Add to your home.nix or packages.nix
environment.systemPackages = with pkgs; [
  docker
  docker-compose
];

# Then run Portainer:
# docker run -d -p 9000:9000 --name portainer \
#   --restart=always \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   portainer/portainer-ce
```

### Alternative 2: Use Podman Desktop
```nix
{
  # Add podman-desktop to your packages
  home.packages = with pkgs; [
    podman-desktop  # GUI for managing containers
  ];
}
```

### Alternative 3: Docker Desktop via Flatpak (Experimental)
```bash
flatpak install flathub io.podman_desktop.PodmanDesktop
```

## Current Status

✅ Docker CLI tools installed in your home-manager  
⚠️  Docker daemon NOT configured (requires system-level setup)  
⚠️  Docker Desktop NOT available on NixOS (use alternatives above)

## Next Steps

1. **Choose your approach**: Docker or Podman
2. **Edit `/etc/nixos/configuration.nix`** with the configuration above
3. **Rebuild your system**: `sudo nixos-rebuild switch`
4. **Log out and back in** for group changes
5. **Test**: `docker run hello-world`

## Troubleshooting

### "Cannot connect to Docker daemon"
- Ensure Docker service is running: `systemctl status docker`
- Check you're in the docker group: `groups`
- Log out and back in after adding yourself to the group

### Permission denied on /var/run/docker.sock
- Make sure your user is in the docker group
- Reboot or log out/in after adding to group

### Docker Desktop alternatives
- Portainer (web-based): Lightweight Docker management UI
- Podman Desktop: Native desktop app for containers
- Lazydocker: Terminal UI for Docker

## ZSH Plugin

You already have the docker plugin enabled in your ZSH configuration, which provides:
- Autocompletion for docker commands
- Useful aliases like `dps` (docker ps), `dex` (docker exec), etc.

Once Docker is set up at the system level, these completions will work automatically!
