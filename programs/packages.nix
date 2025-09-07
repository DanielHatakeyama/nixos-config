{ pkgs, ... }:

with pkgs; [

  xclip # Idk if i need this`
  vscode # Maybe make this a module idk, if i use the config i have might need to do that via a module 

  gcc
  gnumake
  pkg-config

  # Rusty Tools
  fzf
  ripgrep
  fd

  # Imperitive / Ad-Hoc Package Management
  appimage-run
  flatpak

  # Programs profile login custimization
  discord
  obsidian
  tor-browser-bundle-bin # Anonymous web browsing via Tor network
]
