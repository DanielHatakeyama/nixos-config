{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "danielhatakeyama";
    userEmail = "djhatakeyama@gmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };
}
