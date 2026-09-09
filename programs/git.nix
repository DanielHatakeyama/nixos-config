{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "danielhatakeyama";
      user.email = "djhatakeyama@gmail.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };
}
