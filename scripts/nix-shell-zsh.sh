#!/usr/bin/env bash
# Wrapper script to make nix-shell use zsh by default
# This script starts nix-shell but then replaces the shell with zsh

exec env NIX_BUILD_SHELL="${NIX_BUILD_SHELL:-$(command -v bash)}" nix-shell "$@" -c "exec zsh"
