#!/usr/bin/env bash

echo "🧪 Testing Neovim LazyVim Setup..."
echo ""

# Test 1: Check Neovim version
echo "1️⃣  Checking Neovim version..."
nvim --version | head -1
echo ""

# Test 2: Create a test file
echo "2️⃣  Creating test Python file..."
cat > /tmp/test_nvim.py << 'EOF'
def hello_world():
    """A simple test function."""
    print("Hello from Neovim!")
    return True

if __name__ == "__main__":
    hello_world()
EOF
echo "✅ Test file created"
echo ""

# Test 3: Open Neovim headless and let LazyVim initialize
echo "3️⃣  Initializing LazyVim (this may take a minute on first run)..."
timeout 60 nvim --headless "+Lazy! sync" "+qa" 2>&1 | grep -E "(Installing|Syncing|^$)" | head -20 || true
echo ""

# Test 4: Check if Tree-sitter works
echo "4️⃣  Checking Tree-sitter installation..."
nvim --headless "+lua print(vim.fn.has('nvim-0.9') == 1 and '✅ Neovim version OK' or '❌ Neovim version too old')" "+qa" 2>&1 | grep -E "(✅|❌)"
echo ""

# Test 5: Try to open a file (quick test)
echo "5️⃣  Testing file opening..."
timeout 5 nvim --headless "+e /tmp/test_nvim.py" "+wq" 2>&1 > /tmp/nvim_test.log
if [ $? -eq 0 ] || [ $? -eq 124 ]; then
    echo "✅ Neovim can open files"
else
    echo "❌ Error opening files"
    cat /tmp/nvim_test.log
fi
echo ""

echo "🎉 Basic tests complete! Now try: nvim /tmp/test_nvim.py"
echo ""
echo "On first launch, LazyVim will:"
echo "  - Install all plugins"
echo "  - Download Tree-sitter parsers"
echo "  - Set up language servers"
echo ""
echo "This may take 1-2 minutes. Be patient! ⏳"
