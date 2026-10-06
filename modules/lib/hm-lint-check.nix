{ pkgs }:

# Shared by modules/hm-auto-commit.nix (gates the unattended auto-commit) and
# available for manual use (`nix flake check`, the pre-commit hook installed
# via `nix develop`/.envrc run the equivalent checks via flake.nix's
# `preCommitCheck`). Kept as a plain shell script rather than reusing the
# flake's check derivation directly so the activation hook never has to
# `nix build` anything at switch time — it just shells out to tools already
# resolved at eval time, same pattern as hm-generation.nix.
pkgs.writeShellScript "hm-lint-check" ''
  set -uo pipefail
  _dir="''${1:?hm-lint-check: usage: hm-lint-check <dir>}"
  _failed=0

  # -c points statix at $_dir's statix.toml (ignores templates/archive_config)
  # regardless of this script's own invocation cwd.
  if ! ${pkgs.statix}/bin/statix check -c "$_dir" "$_dir"; then
    _failed=1
  fi

  if ! ${pkgs.deadnix}/bin/deadnix --fail --no-lambda-pattern-names \
      --exclude "$_dir/templates" "$_dir/archive_config" -- "$_dir"; then
    _failed=1
  fi

  _nixfiles=$(${pkgs.findutils}/bin/find "$_dir" -name '*.nix' \
    -not -path "$_dir/templates/*" -not -path "$_dir/archive_config/*")
  if [ -n "$_nixfiles" ] && ! ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check $_nixfiles; then
    _failed=1
  fi

  exit "$_failed"
''
