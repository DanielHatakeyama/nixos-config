#!/usr/bin/env bash
set -euo pipefail

# This script configures NixOS to use Hyprland as the default session with GDM.
# It will:
# - Backup /etc/nixos/configuration.nix
# - Disable GNOME desktopManager
# - Set GDM defaultSession to "hyprland"
# - Ensure programs.hyprland is enabled
# - Ensure xdg-desktop-portal-hyprland stack is enabled
# - Rebuild and switch the system

conf="/etc/nixos/configuration.nix"

if [ "${EUID}" -ne 0 ]; then
  echo "Please run with sudo:" >&2
  echo "  sudo $0" >&2
  exit 1
fi

if [ ! -f "$conf" ]; then
  echo "Not a NixOS system or missing $conf" >&2
  exit 1
fi

backup="/etc/nixos/configuration.nix.bak.$(date +%Y%m%d-%H%M%S)"
cp -v "$conf" "$backup"
echo "Backed up to $backup"

# 1) Disable GNOME desktop manager if present
if grep -qE "^\s*services\.xserver\.desktopManager\.gnome\.enable\s*=\s*true;" "$conf"; then
  sed -i -E 's/^\s*services\.xserver\.desktopManager\.gnome\.enable\s*=\s*true;/  services.xserver.desktopManager.gnome.enable = false;/' "$conf"
  echo "Disabled GNOME desktop manager"
else
  echo "GNOME desktop manager already disabled or not present"
fi

# 2) Ensure GDM is enabled (do not force if user disabled explicitly)
if ! grep -qE "^\s*services\.xserver\.displayManager\.gdm\.enable\s*=\s*true;" "$conf"; then
  echo "Note: GDM not enabled in $conf. Enabling so we can select Hyprland." 
  # Insert just after services.xserver.enable line if possible
  awk '
    BEGIN { inserted=0 }
    /services\.xserver\.enable\s*=\s*true;/ && inserted==0 {
      print;
      print "  services.xserver.displayManager.gdm.enable = true;";
      inserted=1;
      next
    }
    { print }
    END { if (inserted==0) print "  services.xserver.displayManager.gdm.enable = true;" }
  ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
fi

# 3) Set default session to hyprland
if grep -q "services.xserver.displayManager.defaultSession" "$conf"; then
  sed -i -E 's/(services\.xserver\.displayManager\.defaultSession\s*=\s*").*(";)/\1hyprland\2/' "$conf"
else
  # Insert right after gdm.enable line
  awk '
    /services\.xserver\.displayManager\.gdm\.enable\s*=\s*true;/ {
      print;
      print "  services.xserver.displayManager.defaultSession = \"hyprland\";";
      next
    }
    { print }
  ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
fi

echo "Ensured default session = hyprland"

# 4) Ensure programs.hyprland is enabled
if grep -qE "^\s*programs\.hyprland\s*=\s*\{" "$conf"; then
  # Ensure enable = true
  if grep -qE "^\s*programs\.hyprland\s*=\s*\{[^{]*$" "$conf" || grep -q "programs.hyprland = {" "$conf"; then
    # Add/replace enable and xwayland lines within the block
    # First, try replacing if they exist
    sed -i -E ':/^\s*programs\.hyprland\s*=\s*\{/,/\}/ s/enable\s*=\s*false;/enable = true;/' "$conf"
    sed -i -E ':/^\s*programs\.hyprland\s*=\s*\{/,/\}/ s/xwayland\.(enable\s*=)\s*false;/xwayland.\1 true;/' "$conf"
    # Then, ensure lines exist
    if ! awk '/^\s*programs\.hyprland\s*=\s*\{/,/\}/ { if ($0 ~ /enable\s*=\s*true;/) found=1 } END { exit(found?0:1) }' "$conf"; then
      awk '
        BEGIN {inblk=0}
        /^\s*programs\.hyprland\s*=\s*\{/ {inblk=1; print; print "    enable = true;"; next}
        inblk==1 && /\}/ {inblk=0; print; next}
        {print}
      ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
    fi
    if ! awk '/^\s*programs\.hyprland\s*=\s*\{/,/\}/ { if ($0 ~ /xwayland\.enable\s*=\s*true;/) found=1 } END { exit(found?0:1) }' "$conf"; then
      awk '
        BEGIN {inblk=0}
        /^\s*programs\.hyprland\s*=\s*\{/ {inblk=1; print; next}
        inblk==1 && /\}/ { print "    xwayland.enable = true;"; inblk=0; print; next}
        {print}
      ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
    fi
  fi
else
  # Append a minimal block before the final closing brace
  sed -i -e '/^}/ i \
  programs.hyprland = {\
\    enable = true;\
\    xwayland.enable = true;\
  };' "$conf"
fi

echo "Ensured programs.hyprland enabled"

### 5) Ensure xdg-desktop-portal stack includes hyprland backend
if ! grep -q "xdg.portal.enable" "$conf"; then
  # Insert portals block before the final closing brace
  sed -i -e '/^}/ i \
  xdg.portal = {\
\    enable = true;\
\    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland xdg-desktop-portal-gtk ];\
  };' "$conf"
else
  # Make sure enable = true
  sed -i -E 's/(xdg\.portal\.enable\s*=\s*)false;/\1true;/' "$conf"
  # Ensure hyprland portal is present
  if ! grep -q "xdg-desktop-portal-hyprland" "$conf"; then
    awk '
      BEGIN {inblk=0}
      /xdg\.portal\s*=\s*\{/ {inblk=1; print; next}
      inblk==1 && /extraPortals/ {
        sub(/\]/," xdg-desktop-portal-hyprland ]"); print; next
      }
      inblk==1 && /\}/ { print "    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland xdg-desktop-portal-gtk ];"; inblk=0; print; next}
      {print}
    ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
  fi
fi

echo "Ensured xdg-desktop-portal-hyprland configured"

echo "--- Preview of updated relevant lines ---"
grep -nE "services\.xserver\.desktopManager\.gnome\.enable|services\.xserver\.displayManager\.(gdm\.enable|defaultSession)|^\s*programs\.hyprland\s*=|xwayland\.enable|enable\s*=\s*true;" "$conf" || true

echo "Rebuilding system..."
nixos-rebuild switch

echo "Sessions available:" || true
ls -1 /run/current-system/sw/share/wayland-sessions 2>/dev/null || true

cat <<EOF

Done. At the GDM login screen:
- Click your username
- Click the gear icon (bottom-right)
- Select "Hyprland"
- Log in

If you prefer not to use GDM, you can switch to greetd/tuigreet later.
EOF
