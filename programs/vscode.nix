{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        eamodio.gitlens
        github.copilot
        github.copilot-chat
        vscodevim.vim
      ];
    };
  };
}
