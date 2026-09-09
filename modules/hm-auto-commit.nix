{ config, lib, pkgs, ... }:

with lib;

# Runs after every successful home-manager switch. If there are uncommitted
# changes in the config directory, stages everything, commits with the current
# generation number, and pushes to the remote.
#
# Works regardless of how the switch was invoked (hms, full command, CI, etc.).
# Respects home-manager's $DRY_RUN_CMD: write operations are skipped during
# `home-manager build`.

let
  cfg = config.djh.hm-auto-commit;
in
{
  options.djh.hm-auto-commit = {
    enable = mkEnableOption "Commit and push config changes after every successful home-manager switch";

    configDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.config/home-manager";
      description = "Path to the home-manager flake repository.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lolcat pkgs.cowsay ];

    home.activation.autoCommit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      _hmdir="${cfg.configDir}"

      if ! ${pkgs.git}/bin/git -C "$_hmdir" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "hm-auto-commit: $_hmdir is not a git repository, skipping."
      elif [ -z "$(${pkgs.git}/bin/git -C "$_hmdir" status --porcelain 2>/dev/null)" ]; then
        echo "hm-auto-commit: nothing to commit."
      else
        # Extract the generation number from the home-manager profile symlink.
        # The symlink target is named: home-manager-<N>-link
        _profile="''${XDG_STATE_HOME:-${config.home.homeDirectory}/.local/state}/nix/profiles/home-manager"
        _link=$(${pkgs.coreutils}/bin/readlink "$_profile" 2>/dev/null || true)
        _base=$(${pkgs.coreutils}/bin/basename "$_link")
        _tmp="''${_base%-*}"   # home-manager-<N>-link → home-manager-<N>
        _gen="''${_tmp##*-}"   # home-manager-<N>     → <N>

        echo "hm-auto-commit: changes detected — staging, committing, and pushing generation $_gen..."

        $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$_hmdir" add -A
        $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$_hmdir" commit \
          -m "chore: switch to home-manager generation $_gen"

        # Push using the nix store openssh so ssh is available in the
        # restricted activation environment (no system PATH).
        if $DRY_RUN_CMD env GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
            ${pkgs.git}/bin/git -C "$_hmdir" push; then
          echo "Generation $_gen committed and pushed." \
            | ${pkgs.cowsay}/bin/cowsay -r \
            | ${pkgs.lolcat}/bin/lolcat
        else
          echo "hm-auto-commit: push failed — commit is saved locally. Run 'git push' when ready."
        fi
      fi
    '';
  };
}
