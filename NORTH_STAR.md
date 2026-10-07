# North Star: Perfect NixOS Configuration

This document captures the long-term vision for this configuration. It serves as a
reference for every cleanup, refactor, and new feature decision. When in doubt,
ask: does this move closer to or further from this document?

---

## Core Philosophy

**Fully declarative.** Every aspect of the system — packages, configuration files,
services, keybindings, themes, secrets — is expressed in Nix. If it is not in this
repository, it does not exist on the system. A fresh NixOS install plus this repo
should reproduce the entire environment exactly.

**No band-aids.** If something requires an imperative script, a manual step after
switching, or a hardcoded path to work, it is not done correctly. Fix the root cause,
not the symptom.

**One command.** The entire system — NixOS configuration and user environment — is
applied with a single command. That command also commits and pushes the change to git.

**Readable and teachable.** The configuration should be clean enough that someone
unfamiliar with it could understand any module in isolation. Comments explain the
"why," not the "what." No informal language, no leftover debug comments, no TODOs
that have been there for months.

**Stable by default, easy to update.** Inputs are pinned. Updates are intentional and
testable. Rolling back is always possible and always safe.

---

## Architecture Vision

### Composed Flakes, Not a Single Repo

Revised 2026-10-06. The end state is **two repositories, composed, not merged**:
`/etc/nixos` stays its own git repo and flake; this home-manager repo stays its
own. `/etc/nixos/flake.nix` takes this repo as a flake input and applies it via
`home-manager.nixosModules.home-manager`, so a single `sudo nixos-rebuild switch`
still applies both atomically — but each repo keeps independent history, CI, and
a fast iteration path (`hms` still works standalone here, without touching the
system at all).

This beats one merged repo for two reasons that matter for how this config is
actually worked on now: declarative-instance switching becomes a matter of which
commit/branch of *this* repo `/etc/nixos`'s flake.lock pins (a different
`nixosConfigurations.<name>` can point at a different ref of this repo, with no
extra machinery), and sub-agents/branches can work at the right granularity —
home-manager-only changes branch this repo, system-level changes branch
`/etc/nixos`, without forcing every change through one lock-step history.

`/etc/nixos` layout (system side):
```
/etc/nixos/
  flake.nix            # nixosConfigurations.nixos; takes this repo as an input
  flake.lock
  configuration.nix    # system-level config (unchanged by the flake wrap)
  hardware-configuration.nix
```

This repo's own layout is unchanged by the above — see the Module Structure
section below.

### Module Structure

Every feature lives in its own module under `modules/`. Modules follow a consistent
pattern: a `djh.<name>` option namespace, an `enable` flag, and all configuration
scoped inside `mkIf`. No module bleeds into another. No inline configuration in
`home.nix` beyond the list of module enables and identity settings.

`home.nix` should read like a manifest — a clean list of what is enabled — not a
configuration file.

`programs/packages.nix` is for general-purpose user environment packages that do not
belong to any specific module. It is a flat list with no inline derivations. Custom
scripts and tools get their own modules.

### Separation of Concerns

| Layer | Owns |
|-------|------|
| NixOS system config | kernel, bootloader, hardware, system services, PipeWire, Hyprland enablement, user accounts, system packages |
| Home-manager modules | per-feature user config, dotfiles, user packages, user services |
| `packages.nix` | general CLI tools with no specific module home |
| `secrets/` | age-encrypted credentials managed by agenix |
| `config/nvim/` | standalone Neovim Lua config, symlinked via home.file |

---

## Feature Goals

### Desktop Environment

- Hyprland is the sole desktop environment. GDM is the login manager (for now).
- Hyprland owns all keyboard remapping (`kb_options` in input config). The GNOME
  module is removed entirely once GDM keyboard handling is addressed properly.
- Wallpaper is tracked in `wallpapers/` and referenced via `home.file`. Hyprpaper
  reads from the nix-managed symlink location.
- A custom login screen and boot splash are eventually configured declaratively.
- Waybar, dunst, rofi, and hyprpaper are all fully declarative with no external
  config files needed.

### Keyboard and Navigation

- Caps Lock → Escape, Alt ↔ Super: configured once, in Hyprland, applied everywhere.
- Super+hjkl navigates Hyprland windows.
- Ctrl+hjkl navigates tmux panes and Neovim splits seamlessly (vim-tmux-navigator).
- No duplication of keybindings across modules.

### Neovim

- Neovim configuration lives as a standalone directory (`config/nvim/`) tracked in
  this repo, symlinked to `~/.config/nvim/` via `home.file`.
- The Nix module installs Neovim, its dependencies, and creates the symlink.
  It does not contain inline Lua strings.
- This means Neovim config can be edited directly without running `home-manager switch`.
- LazyVim handles plugin management. Nix handles the binary and system dependencies.

### Terminal and Shell

- Kitty is the terminal. Configuration is fully declarative, no external scripts.
- Zsh with Oh My Zsh. The `initContent` block contains only minimal, stable additions.
  No hardcoded device names, no imperative workarounds.
- Zoxide, direnv, fzf are standard parts of the shell environment.
- Shell aliases are purposeful and documented. `hms` applies the home-manager config.
  `rebuild` applies the full system config and commits to git.

### Audio

- PipeWire is configured at the system level (NixOS config).
- WirePlumber rules handle device policy (default sink/source, suspend behavior)
  declaratively. No `pactl` commands in shell startup.
- Audio device switching is handled by a proper nix derivation, not a shell script.
- Browser microphone support (WebRTC, PipeWire portal) is configured declaratively
  in the audio module.

### Theme

- Catppuccin Mocha throughout: GTK, Qt, cursors, Neovim, kitty, waybar, dunst.
- A single `djh.theme` module controls the entire theme. Enabling it applies
  consistently across all surfaces. No per-module color overrides.
- The theme module is fixed and re-enabled (it was disabled due to a nixpkgs API
  change in `catppuccin-gtk` that needs updating).

### Development Environments

- Docker and Rust are eventually configured as proper modules with all necessary
  tooling, LSP support, and environment setup declared.
- Per-project development environments use `direnv` + `nix develop` via `flake.nix`
  templates. These are reproducible and do not pollute the global environment.
- The `templates/` directory contains ready-to-use flake templates for common
  project types (Python/FastAPI, Rust, etc.).

### Secrets

- Secrets (API keys, SSH keys, credentials) are managed with agenix.
- Secrets are encrypted at rest in the `secrets/` directory and tracked in git.
- No plaintext secrets ever appear in the repository or the nix store.

### Gaming

- Steam is configured at the system level (already done).
- The home-manager gaming module handles launchers, authentication dependencies,
  and gaming utilities. No redundancy between system and user config.
- GameMode and MangoHud are declaratively configured.

---

## Workflow Vision

### Daily Use

```bash
# Apply home-manager changes
hms

# Apply full system + home-manager (future unified flake)
rebuild
```

`rebuild` is a nix derivation (not a shell script) that:
1. Runs `nixos-rebuild switch --flake .#nixos`
2. On success, stages all changes, commits with the generation number, and pushes

### Updating Inputs

```bash
nix flake update          # update all inputs
hms                       # test with home-manager first
rebuild                   # apply to full system
```

### Adding a New Feature

1. Create `modules/my-feature.nix` following the standard module pattern
2. Import it in `home.nix` (or `configuration.nix` if system-level)
3. Set `djh.my-feature.enable = true` in `home.nix`
4. Run `hms` to test
5. Commit

### Reverting

```bash
# Every generation is tagged automatically (modules/hm-auto-commit.nix) —
# rollback by generation number without reading `home-manager generations`:
git checkout gen/<N>
hms

# Full system rollback (covers home-manager too, since Milestone B):
sudo nixos-rebuild switch --rollback
```

### Branching and Sessions

```bash
# Isolated experimentation: a git worktree + branch, auto-commits stay local
hms --session <name>
cd ~/.config/home-manager-sessions/<name>
# ...edit, then from inside the worktree:
hms                          # tests + auto-commits on session/<name>, never pushes

# When ready (from anywhere):
git -C ~/.config/home-manager-sessions/<name> rebase main   # if main moved on
hms land <name>                                              # ff-merge + push + cleanup
```

---

## What "Done" Looks Like

- `git clone` + `nixos-rebuild switch --flake .#nixos` on a fresh NixOS install
  produces the exact same environment, with zero manual steps afterward.
- `home.nix` is under 50 lines and reads as a clean manifest.
- Every module is self-contained: disable it and nothing else breaks.
- No shell scripts in `scripts/`. No hardcoded paths. No `pactl` in `.zshrc`.
- The GNOME module does not exist.
- The Neovim module is ~30 lines: install package, install deps, create symlink.
- `flake.nix` has fewer than 10 inputs.
- A new person reading any module understands what it does and why within 2 minutes.

---

## Current Status

| Area | Status |
|------|--------|
| Composed flakes (NixOS + HM) | **Done** (2026-10-06) — `/etc/nixos` is a flake composing this repo as an input, not a merged repo (see Architecture Vision above) |
| CI/CD + hooks | **Done** (2026-10-06) — `nix flake check` (statix/deadnix/nixpkgs-fmt + full build) as real flake checks, mirrored in GitHub Actions; `hm-auto-commit` gates every switch on the same checks |
| Generation tagging | **Done** — every generation auto-tagged `gen/<N>` |
| Session/branch workflow | **Done** (2026-10-06) — `hms --session`/`hms land`, branch-aware auto-commit (only `main` auto-pushes) |
| Module structure | Mostly clean — ongoing refinement |
| Dead code removal | Complete for this pass |
| Neovim standalone config | Not started |
| Theme module | Exists but disabled — needs nixpkgs API fix |
| GNOME module removal | Deferred — needs GDM keyboard handling first |
| Audio declarative | Partial — PipeWire at system level, WirePlumber rules in HM, pactl band-aid still in zsh |
| Wallpaper in repo | Not started |
| agenix secrets | Not started |
| Unified rebuild script | **Done** — `sudo nixos-rebuild switch` applies system + home-manager atomically (Milestone B) |
| Keyboard remapping in Hyprland only | Not started — currently split between Hyprland and GNOME module |
| NixOS VM tests | Not started — planned, self-hosted runner on this machine (has KVM) |
| Manager-gated merges / background agents | Not started — deliberately sequenced after the above, see memory `cicd-roadmap` |
