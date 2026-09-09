#!/usr/bin/env bash

# Script to fix Tree-sitter query errors and reinstall parsers

echo "🔧 Fixing Neovim Tree-sitter installation..."

# 1. Remove Tree-sitter plugin and parsers
echo "📦 Removing Tree-sitter plugin..."
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
rm -rf ~/.local/state/nvim/lazy/nvim-treesitter.log

# 2. Clear Tree-sitter cache
echo "🗑️  Clearing Tree-sitter cache..."
rm -rf ~/.cache/nvim/treesitter
rm -rf ~/.local/share/nvim/site/pack/*/start/nvim-treesitter

# 3. Clear parser installations
echo "🧹 Clearing installed parsers..."
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter/parser
rm -rf ~/.local/share/nvim/treesitter

# 4. Open Neovim to trigger reinstall (will exit automatically)
echo "🚀 Launching Neovim to reinstall Tree-sitter..."
nvim --headless "+Lazy! sync nvim-treesitter" "+TSUpdateSync" "+qa" 2>/dev/null || true

echo ""
echo "✅ Tree-sitter has been reset!"
echo ""
echo "Next steps:"
echo "  1. Open Neovim: nvim"
echo "  2. Check health: :checkhealth nvim-treesitter"
echo "  3. Update parsers if needed: :TSUpdate"
echo ""
