{ pkgs }:

# Shared by ../hms.nix and ../hm-auto-commit.nix so the home-manager
# generation-number parsing (reading the profile symlink, e.g.
# "home-manager-270-link" -> "270") exists in exactly one place.
pkgs.writeShellScript "hm-current-generation" ''
  set -euo pipefail
  _profile="''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"
  _link=$(${pkgs.coreutils}/bin/readlink "$_profile" 2>/dev/null || true)
  _base=$(${pkgs.coreutils}/bin/basename "$_link")
  _tmp="''${_base%-*}"
  echo "''${_tmp##*-}"
''
