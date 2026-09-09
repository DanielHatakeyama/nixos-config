{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.djh.claude-code;
in
{
  options.djh.claude-code = {
    enable = mkEnableOption "Claude Code CLI";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
    };
  };
}
