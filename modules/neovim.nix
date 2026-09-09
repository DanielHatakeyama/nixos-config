{ config, lib, pkgs, ... }:


# TODO: Bro i hate this we need to have a normal neovim configuration that nix will pull / symlink with home manager.
# Also neovim should be a system wide configuration
# Maybe add some logic to move around neovim, tmux, and system with super hjkl

with lib;

{
  options.djh.neovim = {
    enable = mkEnableOption "Neovim configuration with LazyVim";
    
    font = {
      size = mkOption {
        type = types.int;
        default = 12;
        description = "Font size for Neovim GUI clients";
      };
    };
  };

  config = mkIf config.djh.neovim.enable {
    # Install required tools and dependencies
    home.packages = with pkgs; [
      # Language servers
      nodejs

      # Tree-sitter CLI for installing parsers
      tree-sitter

      # X11 clipboard support
      xclip
    ];
    
    # Configure neovim through home-manager
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    
    # Set neovim as default editor
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    
    # Copy your LazyVim config to the expected location - standalone configuration
    home.file.".config/nvim/init.lua".text = ''
      -- Ensure proper integration with system clipboard
      vim.opt.clipboard = 'unnamedplus'
      
      -- Terminal colors and compatibility
      vim.opt.termguicolors = true
      
      -- Set font size if in a GUI
      if vim.g.neovide then
        vim.opt.guifont = "FiraCode Nerd Font:h${toString config.djh.neovim.font.size}"
      end
      
      -- Kitty terminal specific optimizations
      if vim.env.TERM == "xterm-kitty" then
        vim.opt.termguicolors = true
        -- Kitty supports undercurl
        vim.g.terminal_color_0 = "#1e1e2e"
        vim.g.terminal_color_8 = "#585b70"
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
      
      -- Disable LazyVim's line move keybindings (Escape+j/k) to avoid accidental triggers
      local map = vim.keymap.set
      map("n", "<Esc>j", "<Nop>", { noremap = true, silent = true, desc = "Disabled (was move line down)" })
      map("n", "<Esc>k", "<Nop>", { noremap = true, silent = true, desc = "Disabled (was move line up)" })

      -- Disable LazyVim's move-line keymaps (Alt-j / Alt-k)
      vim.keymap.del({ "n", "i", "v" }, "<A-j>")
      vim.keymap.del({ "n", "i", "v" }, "<A-k>")

      -- Some terminals report Alt as Meta
      pcall(vim.keymap.del, { "n", "i", "v" }, "<M-j>")
      pcall(vim.keymap.del, { "n", "i", "v" }, "<M-k>")
    '';
    
    home.file.".config/nvim/lua/config/options.lua".text = ''
      -- Options are automatically loaded before lazy.nvim startup
      -- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
      
      -- Terminal color support
      vim.opt.termguicolors = true
      
      -- Better color support for tmux and kitty
      if vim.env.TERM == "xterm-kitty" or vim.env.TERM == "screen-256color" then
        vim.opt.termguicolors = true
      end
      
      -- Transparency settings - give Neovim its own background control
      vim.cmd([[
        augroup NeovimBackgroundSettings
          autocmd!
          " Set a subtle dark background for better readability in Neovim
          autocmd VimEnter * hi Normal guibg=#1a1b26 ctermbg=235
          autocmd VimEnter * hi NonText guibg=#1a1b26 ctermbg=235
          autocmd VimEnter * hi LineNr guibg=#1a1b26 ctermbg=235
          autocmd VimEnter * hi SignColumn guibg=#1a1b26 ctermbg=235
          autocmd VimEnter * hi EndOfBuffer guibg=#1a1b26 ctermbg=235
          
          " Floating windows and popups get a slightly different background
          autocmd VimEnter * hi NormalFloat guibg=#16161e ctermbg=234
          autocmd VimEnter * hi FloatBorder guibg=#16161e ctermbg=234
        augroup END
      ]])
      
      -- Add any additional options here
    '';

    home.file.".config/nvim/lua/plugins/colorscheme.lua".text = ''
      -- Colorscheme configuration
      return {
        -- Tokyo Night colorscheme (LazyVim default, works great with terminals)
        {
          "folke/tokyonight.nvim",
          lazy = false,
          priority = 1000,
          opts = {
            style = "night", -- night, storm, day, moon
            transparent = false, -- Use solid background for better readability
            terminal_colors = true,
            styles = {
              comments = { italic = true },
              keywords = { italic = true },
              functions = {},
              variables = {},
              -- Use solid backgrounds for better contrast
              sidebars = "dark",
              floats = "dark",
            },
          },
        },
        
        -- Catppuccin (another excellent option)
        {
          "catppuccin/nvim",
          name = "catppuccin",
          opts = {
            flavour = "mocha", -- latte, frappe, macchiato, mocha
            background = {
              light = "latte",
              dark = "mocha",
            },
            transparent_background = false, -- Use solid background
            terminal_colors = true,
            integrations = {
              cmp = true,
              gitsigns = true,
              nvimtree = true,
              telescope = true,
              treesitter = true,
            },
          },
        },
        
        -- Configure LazyVim to use Tokyo Night
        {
          "LazyVim/LazyVim",
          opts = {
            colorscheme = "tokyonight-night",
          },
        },
      }
    '';
    
    home.file.".config/nvim/lua/plugins/ui.lua".text = ''
      -- UI enhancements for better color and terminal support
      return {
        -- Better terminal integration
        {
          "akinsho/toggleterm.nvim",
          opts = {
            direction = "float",
            float_opts = {
              border = "curved",
            },
          },
        },
        
        -- Status line with better color support
        {
          "nvim-lualine/lualine.nvim",
          opts = function(_, opts)
            opts.options = opts.options or {}
            opts.options.theme = "tokyonight"
          end,
        },
      }
    '';
    
    # Tree-sitter configuration for syntax highlighting and parsing
    home.file.".config/nvim/lua/plugins/treesitter.lua".text = ''
      -- Tree-sitter configuration - use LazyVim defaults with our customizations
      return {
        {
          "nvim-treesitter/nvim-treesitter",
          opts = {
            ensure_installed = {
              "bash",
              "c",
              "diff",
              "html",
              "javascript",
              "jsdoc",
              "json",
              "jsonc",
              "lua",
              "luadoc",
              "luap",
              "markdown",
              "markdown_inline",
              "python",
              "query",
              "regex",
              "rust",
              "toml",
              "tsx",
              "typescript",
              "vimdoc",
              "xml",
              "yaml",
            },
          },
        },
      }
    '';
    
    # Rust-specific tools and documentation
    home.file.".config/nvim/lua/plugins/rust.lua".text = ''
      return {
        -- Rustaceanvim provides better Rust integration with rust-analyzer
        {
          "mrcjkb/rustaceanvim",
          version = "^4",
          lazy = false,
          ft = { "rust" },
          init = function()
            -- Enable inlay hints by default
            vim.g.rustaceanvim = {
              inlay_hints = {
                highlight = "NonText",
              },
              tools = {
                hover_actions = {
                  auto_jump = false,
                },
              },
              server = {
                on_attach = function(client, bufnr)
                  -- Enable code lens
                  vim.keymap.set("n", "<leader>rr", function()
                    vim.cmd.RustLsp("runnables")
                  end, { silent = true, buffer = bufnr, desc = "Rust runnables" })
                  
                  -- Expand macros
                  vim.keymap.set("n", "<leader>rm", function()
                    vim.cmd.RustLsp("expandMacro")
                  end, { silent = true, buffer = bufnr, desc = "Expand macro" })
                  
                  -- Show type hint
                  vim.keymap.set("n", "K", function()
                    vim.cmd.RustLsp("hover", "Actions")
                  end, { silent = true, buffer = bufnr, desc = "Rust docs/hover" })
                end,
              },
            }
          end,
        },

        -- Docs.rs viewer - lookup crate documentation
        {
          "lbrayner/vim-rzip",
          lazy = false,
        },

        -- Better docs navigation
        {
          "folke/which-key.nvim",
          opts = {
            spec = {
              { "<leader>r", group = "Rust", icon = "🦀" },
            },
          },
        },
      }
    '';
    
    # Obsidian integration for note-taking
    home.file.".config/nvim/lua/plugins/obsidian.lua".text = ''
      return {
        "epwalsh/obsidian.nvim",
        version = "*", -- always latest
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
          workspaces = {
            {
              name = "vault",
              path = "~/vault",
            },
          },
          completion = { nvim_cmp = true },
          -- Use buffer-local keymaps only when in Obsidian vault
          use_path_only = true,
        },
        keys = {
          -- Obsidian-specific keymaps (buffer-local)
          { "go", "<cmd>ObsidianFollowLink<CR>", desc = "Follow Obsidian link" },
          { "gb", "<cmd>ObsidianBacklinks<CR>",  desc = "View backlinks" },
        },
      }
    '';
    
    # Tmux navigator integration
    home.file.".config/nvim/lua/plugins/tmux.lua".text = ''
      return {
        "christoomey/vim-tmux-navigator",
        lazy = false,
        priority = 1001,
        init = function()
          -- Disable default mappings and handle zoomed panes correctly
          vim.g.tmux_navigator_disable_when_zoomed = 1
          vim.g.tmux_navigator_no_mappings = 1
          vim.g.tmux_navigator_no_wrap = 1
        end,
        config = function()
          -- Define a helper to (re)apply our keymaps
          local function apply_tmux_navigator_keymaps()
            local map_opts = { silent = true }
            vim.keymap.set({ "n", "t" }, "<C-h>", "<cmd>TmuxNavigateLeft<CR>", vim.tbl_extend("keep", map_opts, { desc = "Navigate Left" }))
            vim.keymap.set({ "n", "t" }, "<C-j>", "<cmd>TmuxNavigateDown<CR>", vim.tbl_extend("keep", map_opts, { desc = "Navigate Down" }))
            vim.keymap.set({ "n", "t" }, "<C-k>", "<cmd>TmuxNavigateUp<CR>", vim.tbl_extend("keep", map_opts, { desc = "Navigate Up" }))
            vim.keymap.set({ "n", "t" }, "<C-l>", "<cmd>TmuxNavigateRight<CR>", vim.tbl_extend("keep", map_opts, { desc = "Navigate Right" }))
            vim.keymap.set({ "n", "t" }, "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", vim.tbl_extend("keep", map_opts, { desc = "Navigate Previous" }))
          end

          -- Apply keymaps immediately
          apply_tmux_navigator_keymaps()

          -- Re-apply after VeryLazy event to ensure our mappings win
          vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            once = true,
            callback = apply_tmux_navigator_keymaps,
          })
        end,
      }
    '';
    
    # Additional useful plugins
    home.file.".config/nvim/lua/plugins/extras.lua".text = ''
      return {
        -- Enhanced word motions
        {
          "chrisgrieser/nvim-spider",
          lazy = true,
          keys = {
            { "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" }, desc = "Spider-w" },
            { "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" }, desc = "Spider-e" },
            { "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" }, desc = "Spider-b" },
          },
        },
        
        -- Undotree
        {
          "jiaoshijie/undotree",
          dependencies = "nvim-lua/plenary.nvim",
          config = true,
          keys = {
            { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>", desc = "Toggle Undotree" },
          },
        },
      }
    '';

    home.file.".config/nvim/lua/plugins/nix.lua".text = ''
      return {
        { import = "lazyvim.plugins.extras.lang.nix" },

        {
          "neovim/nvim-lspconfig",
          opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.nil_ls = nil
            opts.servers.nixd = {}
          end,
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
