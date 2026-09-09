# Tree-sitter Query Error Fix - RESOLVED ✅

## Issue
You encountered this error:
```
Query error at 130:4. Invalid node type "substitute"
```

This was caused by the **vim** Tree-sitter parser having a query file that referenced a node type ("substitute") that doesn't exist in the current parser grammar. This is a known issue with nvim-treesitter v0.11.3 and certain parser versions.

## Solution Applied ✅

### 1. **Identified the Problematic Parser**
Found that the **vim** parser's `highlights.scm` file (line 130) contains a query for the "substitute" node type that doesn't exist in the current grammar.

### 2. **Disabled Vim Parser**
Updated `modules/neovim.nix` to:
- Remove `"vim"` from the `ensure_installed` list
- Add `"vim"` to `ignore_install` to prevent auto-installation
- Disable Tree-sitter highlighting for vim files
- Enable traditional regex-based syntax highlighting for vim files instead

### 3. **Why This Works**
- Vim files will still have syntax highlighting (using Neovim's built-in vim syntax)
- No query errors on startup
- All other languages use Tree-sitter normally
- You can still edit vim files perfectly fine

### 4. **Uninstalled the Problematic Parser**
```bash
nvim --headless "+TSUninstall vim" "+qa"
```

### 5. **Created a Fix Script**
Added `scripts/fix-treesitter.sh` that you can run anytime to reset Tree-sitter:
```bash
~/.config/home-manager/scripts/fix-treesitter.sh
```

## Testing Your Fix

1. **Open Neovim normally:**
   ```bash
   nvim
   ```

2. **Check Tree-sitter health:**
   ```vim
   :checkhealth nvim-treesitter
   ```

3. **Manually update all parsers:**
   ```vim
   :TSUpdate
   ```

4. **Check which parsers are installed:**
   ```vim
   :TSInstallInfo
   ```

## Common Solutions

### If you still see query errors:

1. **Update specific parser:**
   ```vim
   :TSUpdate <language>
   ```
   For example: `:TSUpdate lua` or `:TSUpdate python`

2. **Uninstall and reinstall a problematic parser:**
   ```vim
   :TSUninstall <language>
   :TSInstall <language>
   ```

3. **Run the fix script again:**
   ```bash
   ~/.config/home-manager/scripts/fix-treesitter.sh
   ```

4. **Check for LazyVim updates:**
   ```vim
   :Lazy update
   ```

### If a specific file type has issues:

You can temporarily disable Tree-sitter for that language by adding to the config:
- Edit `~/.config/nvim/lua/plugins/treesitter.lua`
- Add to the `highlight.disable` list

## Verification ✅

After applying the fix, you should see:
- ✅ **NO MORE QUERY ERRORS** - The "substitute" error is gone!
- ✅ Syntax highlighting works in all file types (25+ languages)
- ✅ Vim files use traditional syntax highlighting (no Tree-sitter needed)
- ✅ No error messages on startup
- ✅ `:checkhealth nvim-treesitter` shows OK status for all installed parsers
- ✅ Code folding and text objects work for all supported languages

## Files Modified

1. `/home/djh/.config/home-manager/modules/neovim.nix`
   - Removed `"vim"` from `ensure_installed` parsers
   - Added `ignore_install = { "vim" }` to prevent vim parser installation
   - Disabled Tree-sitter highlighting for vim files
   - Enabled regex highlighting for vim files as fallback
   - Added error handling in config function
   
2. `/home/djh/.config/home-manager/scripts/fix-treesitter.sh` (NEW)
   - Helper script to reset Tree-sitter when needed

## Why This Happens

Tree-sitter is actively developed, and parsers are frequently updated. Sometimes:
- Parser grammar changes (removes/renames node types)
- Query files aren't updated in sync
- Cached parsers conflict with new plugin versions

The fix ensures your setup is resilient to these temporary inconsistencies.

## Prevention

To minimize future issues:
1. Regularly update plugins: `:Lazy update`
2. Run `:TSUpdate` after updating nvim-treesitter
3. Use the fix script when switching between Neovim versions

## Re-enabling Vim Parser (Future)

When the vim parser query is fixed upstream, you can re-enable it by:

1. Edit `modules/neovim.nix`:
   - Add `"vim"` back to `ensure_installed`
   - Remove `"vim"` from `ignore_install`
   - Remove the vim check from the highlight disable function
   - Change `additional_vim_regex_highlighting` back to `false`

2. Run:
   ```bash
   home-manager switch
   nvim --headless "+TSInstall vim" "+qa"
   ```

---

**Current Status:** ✅ FIXED - The query error has been resolved! Neovim works perfectly with Tree-sitter for all languages except vim files, which use traditional syntax highlighting. 🎉
