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
    # Install neovim and required packages
    home.packages = with pkgs; [
      neovim
      # Language servers and tools that LazyVim might need
      ripgrep
      fd
      git
      nodejs
      gcc
      gnumake
      pkg-config
      
      # Clipboard support for headless environments
      xclip
      wl-clipboard
    ];
    
    # Set neovim as default editor
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    
    # Add shell aliases
    home.shellAliases = {
      vi = "nvim";
      vim = "nvim";
      vimdiff = "nvim -d";
    };
    
    # Copy your LazyVim config to the expected location - standalone configuration
    home.file.".config/nvim/init.lua".text = ''
      -- Ensure proper integration with system clipboard
      vim.opt.clipboard = 'unnamedplus'
      
      -- Set font size if in a GUI
      if vim.g.neovide then
        vim.opt.guifont = "FiraCode Nerd Font:h${toString config.djh.neovim.font.size}"
      end
      
      -- bootstrap lazy.nvim, LazyVim and your plugins
      require("config.lazy")
    '';
    
    home.file.".config/nvim/lua/config/lazy.lua".text = ''
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
          }, true, {})
          vim.fn.getchar()
          os.exit(1)
        end
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          -- add LazyVim and import its plugins
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          -- import your plugins
          { import = "plugins" },
        },
        defaults = {
          -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
          -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
          lazy = false,
          -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
          -- have outdated releases, which may break your Neovim install.
          version = false, -- always use the latest git commit
        },
        install = { colorscheme = { "tokyonight", "habamax" } },
        checker = { enabled = true }, -- automatically check for plugin updates
        performance = {
          rtp = {
            -- disable some rtp plugins
            disabled_plugins = {
              "gzip",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
    '';
    
    home.file.".config/nvim/lua/config/autocmds.lua".text = ''
      -- Autocmds are automatically loaded on the VeryLazy event
      -- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
      -- Add any additional autocmds here
    '';
    
    home.file.".config/nvim/lua/config/keymaps.lua".text = ''
      -- Keymaps are automatically loaded on the VeryLazy event
      -- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
      -- Add any additional keymaps here
    '';
    
    home.file.".config/nvim/lua/config/options.lua".text = ''
      -- Options are automatically loaded before lazy.nvim startup
      -- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
      -- Add any additional options here
    '';
    
    home.file.".config/nvim/lua/plugins/example.lua".text = ''
      -- Every spec file under the "plugins" directory will be loaded automatically by Lazy
      -- This file shows how to add custom plugins

      return {
        -- add gruvbox colorscheme
        { "ellisonleao/gruvbox.nvim" },

        -- Configure LazyVim to load gruvbox
        {
          "LazyVim/LazyVim",
          opts = {
            colorscheme = "gruvbox",
          },
        },
      }
    '';
    
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
