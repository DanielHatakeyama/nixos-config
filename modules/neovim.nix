{ config, lib, pkgs, ... }:

with lib;

{
  options.djh.neovim = {
    enable = mkEnableOption "Neovim configuration with LazyVim";
    
    font = {
      size = mkOption {
        type = types.int;
        default = 13;
        description = "Font size for Neovim GUI clients";
      };
    };
  };

  config = mkIf config.djh.neovim.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      
      # Enable system clipboard integration
      extraPackages = with pkgs; [
        # Language servers and tools that your LazyVim config might need
        ripgrep
        fd
        git
        nodejs
        
        # Clipboard support for headless environments
        xclip
        wl-clipboard
      ];
      
      # Set environment variables for better integration
      extraLuaConfig = ''
        -- Ensure proper integration with system clipboard
        vim.opt.clipboard = 'unnamedplus'
        
        -- Set font size if in a GUI
        if vim.g.neovide then
          vim.opt.guifont = "FiraCode Nerd Font:h${toString config.djh.neovim.font.size}"
        end
      '';
    };
    
    # Copy your archived LazyVim config to the expected location
    home.file.".config/nvim" = {
      source = ../archive_config/dotfiles-mac-wk/nvim;
      recursive = true;
    };
    
    # Create a desktop entry for GUI neovim clients
    xdg.desktopEntries.nvim = mkIf pkgs.stdenv.isLinux {
      name = "Neovim";
      comment = "Edit text files";
      exec = "nvim %F";
      icon = "nvim";
      terminal = true;
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
    };
  };
}
