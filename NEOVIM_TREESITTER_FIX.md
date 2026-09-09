# Neovim LazyVim Tree-sitter Fix

## What Was Fixed

Your Neovim LazyVim setup was missing a proper Tree-sitter configuration, which is essential for modern syntax highlighting, code parsing, and text objects. Here's what was added:

### 1. **Tree-sitter CLI Package** 
Added `tree-sitter` to your Nix packages in `modules/neovim.nix` to ensure the Tree-sitter CLI is available for installing and compiling parsers.

### 2. **Comprehensive Tree-sitter Plugin Configuration**
Created a new plugin file `.config/nvim/lua/plugins/treesitter.lua` with:

- **Auto-install**: Automatically installs missing parsers when you open files
- **25+ Language Parsers**: Pre-configured parsers for common languages including:
  - Nix, Lua, Python, JavaScript/TypeScript, Bash
  - HTML, CSS, JSON, YAML, TOML, Markdown
  - Git-related files, Vim/Neovim config files
  - And many more

- **Syntax Highlighting**: 
  - Enabled with performance optimizations
  - Automatically disables for files > 100KB to prevent slowdowns
  - No conflicting regex highlighting

- **Smart Indentation**: 
  - Tree-sitter-based indentation (disabled for Python/YAML where it can cause issues)

- **Incremental Selection**:
  - `<C-space>`: Expand selection to next node
  - `<bs>`: Shrink selection

- **Text Objects**:
  - `af`/`if`: Function outer/inner
  - `ac`/`ic`: Class outer/inner
  - `aa`/`ia`: Parameter outer/inner
  - Navigation: `]f`, `[f` (functions), `]c`, `[c` (classes)

### 3. **Tmux Navigator Integration**
Added the `vim-tmux-navigator` plugin configuration for seamless navigation between Neovim and Tmux panes using `<C-h/j/k/l>`.

### 4. **Additional Useful Plugins**
- **nvim-spider**: Enhanced word motions for more intelligent `w`, `e`, `b` movements
- **undotree**: Visual undo history tree (`<leader>u`)

## How to Apply the Fix

1. **Rebuild your home-manager configuration**:
   ```bash
   home-manager switch
   ```

2. **Open Neovim**:
   ```bash
   nvim
   ```

3. **Let Lazy.nvim sync plugins**:
   On first launch, LazyVim will automatically:
   - Download the Tree-sitter plugin
   - Install all configured parsers
   - Set up syntax highlighting

   You can also manually trigger updates:
   - Press `:Lazy` to open the Lazy.nvim UI
   - Press `S` to sync all plugins
   - Press `:TSUpdate` to update all Tree-sitter parsers

4. **Verify Tree-sitter is working**:
   ```vim
   :checkhealth nvim-treesitter
   ```

## What You Should See

After applying these changes:
- ✅ Better syntax highlighting with semantic colors
- ✅ Proper code folding based on syntax structure
- ✅ Working text objects for functions, classes, and parameters
- ✅ Intelligent incremental selection
- ✅ No more "tree-sitter not found" or outdated parser warnings
- ✅ Seamless Tmux/Neovim navigation

## Troubleshooting

If you encounter issues:

1. **Clear Neovim cache**:
   ```bash
   rm -rf ~/.local/share/nvim
   rm -rf ~/.cache/nvim
   ```

2. **Reinstall parsers**:
   ```vim
   :TSUninstall all
   :TSUpdate
   ```

3. **Check health**:
   ```vim
   :checkhealth
   ```

## Configuration Location

All changes were made to:
- `/home/djh/.config/home-manager/modules/neovim.nix`

The configuration generates these files in your home directory:
- `~/.config/nvim/init.lua`
- `~/.config/nvim/lua/config/lazy.lua`
- `~/.config/nvim/lua/config/options.lua`
- `~/.config/nvim/lua/config/keymaps.lua`
- `~/.config/nvim/lua/config/autocmds.lua`
- `~/.config/nvim/lua/plugins/colorscheme.lua`
- `~/.config/nvim/lua/plugins/treesitter.lua` (NEW)
- `~/.config/nvim/lua/plugins/ui.lua`
- `~/.config/nvim/lua/plugins/tmux.lua` (NEW)
- `~/.config/nvim/lua/plugins/obsidian.lua`
- `~/.config/nvim/lua/plugins/extras.lua` (NEW)

Enjoy your properly configured LazyVim setup with working Tree-sitter!
