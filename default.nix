# Default.nix for backwards compatibility
# This allows the configuration to work with both flakes and traditional nix commands

{ pkgs ? import <nixpkgs> {} }:

import ./home.nix { inherit pkgs; config = {}; }
