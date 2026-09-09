{ config, lib, pkgs, ... }:

with lib;

# Wrapper around `home-manager switch` that:
#   - Pins the flake target to this user's config (no need to type it each time)
#   - Suppresses the dirty-tree warning (expected since auto-commit runs post-switch)
#   - Optionally creates and pushes an annotated git tag after a successful switch:
#       hms --tag "before-flake-update"
#
# Extra arguments are passed through to `home-manager switch` unchanged.

let
  cfg = config.djh.hms;
  configDir = "${config.home.homeDirectory}/.config/home-manager";
  flakeTarget = "${configDir}#${config.home.username}";
in
{
  options.djh.hms = {
    enable = mkEnableOption "hms - home-manager switch wrapper with optional git tagging";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "hms" ''
        set -euo pipefail

        TAG=""
        HM_ARGS=()

        # Parse arguments: pull out --tag <name>, pass everything else through.
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --tag)
              TAG="''${2:?hms: --tag requires a value}"
              shift 2
              ;;
            --help|-h)
              echo "Usage: hms [--tag <name>] [home-manager switch args...]"
              echo ""
              echo "  --tag <name>  Create and push an annotated git tag after switching."
              echo ""
              echo "All other arguments are forwarded to 'home-manager switch'."
              exit 0
              ;;
            *)
              HM_ARGS+=("$1")
              shift
              ;;
          esac
        done

        # Record HEAD before the switch so we can detect whether auto-commit
        # made a new commit (used for accurate tag messaging below).
        HEAD_BEFORE=$(${pkgs.git}/bin/git -C "${configDir}" rev-parse HEAD 2>/dev/null || echo "none")

        # NIX_CONFIG suppresses the "dirty tree" warning. The tree is dirty by
        # design — uncommitted changes exist at eval time because auto-commit
        # runs after the switch completes, not before.
        if [[ ''${#HM_ARGS[@]} -gt 0 ]]; then
          NIX_CONFIG="warn-dirty = false" home-manager switch \
            --flake "${flakeTarget}" \
            "''${HM_ARGS[@]}"
        else
          NIX_CONFIG="warn-dirty = false" home-manager switch \
            --flake "${flakeTarget}"
        fi

        # Apply the tag after a successful switch. The auto-commit hook has
        # already run at this point, so the tag lands on the correct commit.
        if [[ -n "$TAG" ]]; then
          HEAD_AFTER=$(${pkgs.git}/bin/git -C "${configDir}" rev-parse HEAD 2>/dev/null || echo "none")

          ${pkgs.git}/bin/git -C "${configDir}" tag -a "$TAG" -m "$TAG"
          GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
            ${pkgs.git}/bin/git -C "${configDir}" push --tags

          if [[ "$HEAD_BEFORE" != "$HEAD_AFTER" ]]; then
            # A new commit was made by the auto-commit hook.
            _profile="''${XDG_STATE_HOME:-${config.home.homeDirectory}/.local/state}/nix/profiles/home-manager"
            _link=$(${pkgs.coreutils}/bin/readlink "$_profile" 2>/dev/null || true)
            _base=$(${pkgs.coreutils}/bin/basename "$_link")
            _tmp="''${_base%-*}"
            _gen="''${_tmp##*-}"
            echo "hms: tag '$TAG' applied to generation $_gen and pushed."
          else
            # No config changes — tag landed on the previous commit.
            echo "hms: no config changes — tag '$TAG' applied to current HEAD and pushed."
          fi
        fi
      '')
    ];
  };
}
