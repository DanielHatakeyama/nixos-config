{ config, lib, pkgs, ... }:

with lib;

# Wrapper around `home-manager switch`, plus the session/worktree primitives
# that make branch-based experimentation possible:
#
#   hms [--tag <name>] [switch args...]
#     Apply the config. Targets $PWD if it looks like a home-manager flake
#     checkout (e.g. a session worktree); otherwise the main repo. Suppresses
#     the dirty-tree warning (expected — auto-commit runs post-switch) and
#     optionally tags the resulting commit.
#
#   hms --session <name>
#     Create a git worktree + branch `session/<name>`, forked from main, for
#     isolated experimentation. `hms` run from inside it auto-commits on
#     that branch but never pushes (see modules/hm-auto-commit.nix) until
#     landed.
#
#   hms land <name>
#     Fast-forward `session/<name>` into main, push, and remove the
#     worktree. Refuses (with instructions) if the branch isn't already a
#     fast-forward of main — rebase in the worktree first.
let
  cfg = config.djh.hms;
  configDir = "${config.home.homeDirectory}/.config/home-manager";
  sessionsDir = "${config.home.homeDirectory}/.config/home-manager-sessions";
  username = config.home.username;
  currentGeneration = import ./lib/hm-generation.nix { inherit pkgs; };
in
{
  options.djh.hms = {
    enable = mkEnableOption "hms - home-manager switch wrapper with git tagging and session worktrees";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "hms" ''
        set -euo pipefail

        TAG=""
        SESSION=""
        LAND=""
        HM_ARGS=()

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --tag)
              TAG="''${2:?hms: --tag requires a value}"
              shift 2
              ;;
            --session)
              SESSION="''${2:?hms: --session requires a name}"
              shift 2
              ;;
            land)
              LAND="''${2:?hms land requires a session name}"
              shift 2
              ;;
            --help|-h)
              cat <<'USAGE'
        Usage:
          hms [--tag <name>] [home-manager switch args...]
              Apply the config. Targets $PWD if it's a home-manager flake
              checkout (e.g. a session worktree), else the main repo.

          hms --session <name>
              Create a git worktree + branch 'session/<name>' for isolated
              experimentation. Auto-commits there stay local (never pushed)
              until landed.

          hms land <name>
              Fast-forward-merge 'session/<name>' into main, push, and clean
              up the worktree. Fails with instructions if the branch isn't
              rebased onto the latest main yet.
        USAGE
              exit 0
              ;;
            *)
              HM_ARGS+=("$1")
              shift
              ;;
          esac
        done

        if [[ -n "$SESSION" ]]; then
          _worktree="${sessionsDir}/$SESSION"
          if [[ -e "$_worktree" ]]; then
            echo "hms: session '$SESSION' already exists at $_worktree" >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/mkdir -p "${sessionsDir}"
          ${pkgs.git}/bin/git -C "${configDir}" worktree add "$_worktree" -b "session/$SESSION" main
          echo "hms: session worktree created at $_worktree on branch session/$SESSION"
          echo "hms: cd there and edit, then run 'hms' from inside it to test and auto-commit locally."
          echo "hms: when ready: git -C \"$_worktree\" rebase main, then 'hms land $SESSION' from anywhere."
          exit 0
        fi

        if [[ -n "$LAND" ]]; then
          _worktree="${sessionsDir}/$LAND"
          _branch="session/$LAND"
          if ! ${pkgs.git}/bin/git -C "${configDir}" rev-parse --verify "$_branch" > /dev/null 2>&1; then
            echo "hms: no such session branch '$_branch'" >&2
            exit 1
          fi
          if [[ -d "$_worktree" ]] && [[ -n "$(${pkgs.git}/bin/git -C "$_worktree" status --porcelain 2>/dev/null)" ]]; then
            echo "hms: session worktree has uncommitted changes — commit or discard them first." >&2
            exit 1
          fi
          ${pkgs.git}/bin/git -C "${configDir}" checkout main
          if ! ${pkgs.git}/bin/git -C "${configDir}" merge --ff-only "$_branch"; then
            echo "hms: '$_branch' isn't a fast-forward of main. Rebase it first:" >&2
            echo "  git -C \"$_worktree\" rebase main" >&2
            exit 1
          fi
          GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" ${pkgs.git}/bin/git -C "${configDir}" push
          if [[ -d "$_worktree" ]]; then
            ${pkgs.git}/bin/git -C "${configDir}" worktree remove "$_worktree"
          fi
          ${pkgs.git}/bin/git -C "${configDir}" branch -d "$_branch"
          echo "hms: landed '$_branch' into main and pushed. Run 'hms' to activate it."
          exit 0
        fi

        # Default: apply the config. Target $PWD when it looks like a
        # home-manager flake checkout (e.g. a session worktree); otherwise
        # the main repo. HM_CONFIG_DIR tells the auto-commit activation
        # hook which directory it's actually operating on — it can't infer
        # that from its Nix-eval-time default alone once more than one
        # checkout of this flake exists on disk.
        if [[ -f "$PWD/flake.nix" ]] && ${pkgs.git}/bin/git -C "$PWD" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
          _hmdir="$PWD"
        else
          _hmdir="${configDir}"
        fi
        export HM_CONFIG_DIR="$_hmdir"
        _flaketarget="$_hmdir#${username}"

        # Record HEAD before the switch so we can detect whether auto-commit
        # made a new commit (used for accurate tag messaging below).
        HEAD_BEFORE=$(${pkgs.git}/bin/git -C "$_hmdir" rev-parse HEAD 2>/dev/null || echo "none")

        # NIX_CONFIG suppresses the "dirty tree" warning. The tree is dirty by
        # design — uncommitted changes exist at eval time because auto-commit
        # runs after the switch completes, not before.
        if [[ ''${#HM_ARGS[@]} -gt 0 ]]; then
          NIX_CONFIG="warn-dirty = false" home-manager switch \
            --flake "$_flaketarget" \
            "''${HM_ARGS[@]}"
        else
          NIX_CONFIG="warn-dirty = false" home-manager switch \
            --flake "$_flaketarget"
        fi

        # Apply the tag after a successful switch. The auto-commit hook has
        # already run at this point, so the tag lands on the correct commit.
        if [[ -n "$TAG" ]]; then
          HEAD_AFTER=$(${pkgs.git}/bin/git -C "$_hmdir" rev-parse HEAD 2>/dev/null || echo "none")

          ${pkgs.git}/bin/git -C "$_hmdir" tag -a "$TAG" -m "$TAG"
          GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
            ${pkgs.git}/bin/git -C "$_hmdir" push --tags

          if [[ "$HEAD_BEFORE" != "$HEAD_AFTER" ]]; then
            # A new commit was made by the auto-commit hook.
            _gen=$(${currentGeneration})
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
