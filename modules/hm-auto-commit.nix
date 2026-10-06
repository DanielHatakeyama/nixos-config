{ config, lib, pkgs, ... }:

with lib;

# Runs after every successful home-manager switch. If there are uncommitted
# changes in the config directory, scans them for credential-shaped files and
# secret-shaped content, then (if clean) stages everything, commits with the
# current generation number, and pushes to the remote.
#
# Works regardless of how the switch was invoked (hms, full command, CI, etc.).
# Respects home-manager's $DRY_RUN_CMD: write operations are skipped during
# `home-manager build`.

let
  cfg = config.djh.hm-auto-commit;
  currentGeneration = import ./lib/hm-generation.nix { inherit pkgs; };
  lintCheck = import ./lib/hm-lint-check.nix { inherit pkgs; };

  # Filename globs that should never be auto-committed, matched against each
  # changed path's lowercased basename. Covers credential stores, private
  # keys, env files, shell/DB history, etc.
  denylistPatterns = [
    "credentials*"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "*.kdbx"
    "id_rsa*"
    "id_ed25519*"
    "id_ecdsa*"
    "id_dsa*"
    ".env"
    ".env.*"
    ".netrc"
    ".npmrc"
    ".pgpass"
    "*_history"
    "*.sqlite"
    "*.sqlite3"
    "*.db"
  ] ++ cfg.extraDenylistPatterns;

  # High-confidence secret shapes (AWS keys, private key headers, Slack/
  # GitHub/Google tokens), scanned only in the files actually being
  # committed. Deliberately narrow to avoid false positives on ordinary
  # words like "secret" or "key" in comments/package names.
  contentPatterns = [
    "AKIA[0-9A-Z]{16}"
    "-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"
    "xox[baprs]-[0-9A-Za-z-]{10,}"
    "gh[pousr]_[0-9A-Za-z]{30,}"
    "AIza[0-9A-Za-z_-]{30,}"
  ] ++ cfg.extraContentPatterns;

  denylistCase = concatStringsSep "|" denylistPatterns;
  contentRegex = concatStringsSep "|" contentPatterns;
in
{
  options.djh.hm-auto-commit = {
    enable = mkEnableOption "Commit and push config changes after every successful home-manager switch";

    configDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.config/home-manager";
      description = "Path to the home-manager flake repository.";
    };

    extraDenylistPatterns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra lowercase filename glob patterns to block from auto-commit,
        matched against each changed file's lowercased basename.
      '';
    };

    extraContentPatterns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra extended-regex patterns to scan changed file contents for.
        A match blocks the auto-commit the same as a denylisted filename.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.activation.autoCommit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      _hmdir="${cfg.configDir}"

      if ! ${pkgs.git}/bin/git -C "$_hmdir" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "hm-auto-commit: $_hmdir is not a git repository, skipping."
      elif [ -z "$(${pkgs.git}/bin/git -C "$_hmdir" status --porcelain 2>/dev/null)" ]; then
        echo "hm-auto-commit: nothing to commit."
      else
        # --- Safety scan: refuse to auto-commit anything that looks like a
        # credential, key, or secret. Runs before `git add`, so a match
        # leaves the working tree exactly as it was for manual handling.
        _blocked=()

        while IFS= read -r _line; do
          [ -z "$_line" ] && continue
          _path="''${_line:3}"
          case "$_path" in
            *" -> "*) _path="''${_path#*" -> "}" ;;
          esac

          _base=$(${pkgs.coreutils}/bin/basename "$_path")
          _basel=$(printf '%s' "$_base" | ${pkgs.coreutils}/bin/tr 'A-Z' 'a-z')

          case "$_basel" in
            ${denylistCase})
              _blocked+=("$_path  (blocked filename pattern)")
              continue
              ;;
          esac

          if [ -f "$_hmdir/$_path" ] \
              && ${pkgs.gnugrep}/bin/grep -qIE '${contentRegex}' "$_hmdir/$_path" 2>/dev/null; then
            _blocked+=("$_path  (looks like a secret/credential)")
          fi
        done <<< "$(${pkgs.git}/bin/git -C "$_hmdir" status --porcelain)"

        if [ ''${#_blocked[@]} -gt 0 ]; then
          echo "hm-auto-commit: BLOCKED — the following changed file(s) look like credentials/secrets:"
          for _b in "''${_blocked[@]}"; do
            echo "  - $_b"
          done
          echo "hm-auto-commit: fix, remove, or .gitignore these, then re-run the switch. Nothing was staged, committed, or pushed."
        else
          # --- Quality gate: statix, deadnix, and nixpkgs-fmt (see
          # modules/lib/hm-lint-check.nix) must pass before anything is
          # staged. A failure leaves the tree dirty, same as the secret
          # scan above, and writes the full output to a fixed path. That
          # path is the intended hook for future automation (e.g. a
          # subagent/CI-checker routine) to read, decide how to fix the
          # issue, and re-run the switch — nothing reads it yet.
          _failurelog="$_hmdir/.hm-auto-commit-last-failure.log"
          if ! ${lintCheck} "$_hmdir" > "$_failurelog" 2>&1; then
            echo "hm-auto-commit: BLOCKED — lint/format checks failed:"
            ${pkgs.coreutils}/bin/cat "$_failurelog"
            echo "hm-auto-commit: fix the issues above (try 'nix fmt' for formatting), then re-run the switch."
            echo "hm-auto-commit: full output left at $_failurelog. Nothing was staged, committed, or pushed."
          else
            ${pkgs.coreutils}/bin/rm -f "$_failurelog"

            # Generation number may be unchanged from the last auto-commit if
            # the source edit evaluated to an identical build (e.g. a comment
            # or an equivalent string form) — say so honestly instead of
            # implying a new generation that doesn't exist.
            _gen=$(${currentGeneration})
            _last_msg=$(${pkgs.git}/bin/git -C "$_hmdir" log -1 --format=%s 2>/dev/null || echo "")
            _is_new_gen=true
            if [ "$_last_msg" = "chore: switch to home-manager generation $_gen" ]; then
              _msg="chore: config update (generation $_gen unchanged — no new build output)"
              _is_new_gen=false
            else
              _msg="chore: switch to home-manager generation $_gen"
            fi

            echo "hm-auto-commit: changes detected — staging, committing, and pushing..."
            echo "hm-auto-commit: $_msg"

            $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$_hmdir" add -A
            $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$_hmdir" commit -m "$_msg"

            # One annotated tag per generation (gen/<N>), so every generation
            # is a durable git ref regardless of whether `hms --tag` was used
            # — rollback becomes `git checkout gen/<N>` and history is
            # bisectable by generation without reading `home-manager
            # generations` output.
            if [ "$_is_new_gen" = true ] \
                && ! ${pkgs.git}/bin/git -C "$_hmdir" rev-parse "gen/$_gen" > /dev/null 2>&1; then
              $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$_hmdir" tag -a "gen/$_gen" -m "generation $_gen"
            fi

            # Push using the nix store openssh so ssh is available in the
            # restricted activation environment (no system PATH).
            # --follow-tags carries the gen/<N> tag along in the same push.
            if $DRY_RUN_CMD env GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
                ${pkgs.git}/bin/git -C "$_hmdir" push --follow-tags; then
              echo "$_msg" \
                | ${pkgs.cowsay}/bin/cowsay -r \
                | ${pkgs.lolcat}/bin/lolcat
            else
              echo "hm-auto-commit: push failed — commit is saved locally. Run 'git push --follow-tags' when ready."
            fi
          fi
        fi
      fi
    '';
  };
}
