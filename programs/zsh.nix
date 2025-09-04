{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    
    # Enable oh-my-zsh
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell"; # Default theme, you can change this
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
        "history-substring-search"
      ];
    };
    
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    
    history = {
      size = 10000;
      ignoreDups = true;
    };
    
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      hm = "home-manager";
    };
  };
}
