# Zoxide - Smart CD Replacement

## What is Zoxide?

Zoxide is a smarter `cd` command written in Rust that remembers which directories you use most frequently, allowing you to jump to them with just a few keystrokes.

## Installation ✅

Zoxide has been installed and configured in your zsh with:
- `cd` aliased to `z` (zoxide)
- Automatic zsh integration enabled

## How to Activate

**Restart your shell:**
```bash
exec zsh
```

Or open a new terminal window.

## Usage

### Basic Commands

**Jump to a directory (learns from your usage):**
```bash
z documents      # Jump to ~/Documents
z proj           # Jump to ~/projects
z conf nix       # Jump to ~/.config/nixos
```

**Use cd normally (it's aliased to z):**
```bash
cd documents     # Same as 'z documents'
```

### Advanced Commands

**Jump to a directory with interactive selection:**
```bash
zi documents     # Opens interactive fuzzy finder
```

**List all directories in the database:**
```bash
zoxide query -l
```

**Remove a directory from the database:**
```bash
zoxide remove /path/to/directory
```

### How Zoxide Learns

Zoxide tracks:
- **Frequency**: How often you visit a directory
- **Recency**: How recently you visited it

The more you use a directory, the easier it becomes to jump to it!

### Examples

```bash
# After visiting these directories a few times:
cd ~/projects/my-app
cd ~/Documents/work
cd ~/.config/nixos

# You can later jump with just:
z app          # Goes to ~/projects/my-app
z work         # Goes to ~/Documents/work
z nixos        # Goes to ~/.config/nixos
```

### Tips

1. **Be specific at first**: Visit directories normally at first so zoxide can learn
2. **Use short, unique keywords**: `z proj` is faster than `z projects/subfolder/deep`
3. **Combine with other tools**: Works great with fzf for fuzzy finding
4. **Case insensitive**: `z DOCS` = `z docs`

## Configuration Location

- **Zoxide config**: `~/.config/home-manager/programs/zsh.nix`
- **Database**: `~/.local/share/zoxide/db.zo`

## Commands Reference

| Command | Description |
|---------|-------------|
| `z <keyword>` | Jump to highest ranked directory matching keyword |
| `zi <keyword>` | Interactive selection with fzf |
| `z -` | Go to previous directory |
| `z ..` | Go up one directory (still works!) |
| `zoxide query <keyword>` | Display the best match |
| `zoxide query -l` | List all directories |
| `zoxide remove <path>` | Remove directory from database |

## Why Zoxide?

- ⚡ **Blazingly fast** - Written in Rust
- 🧠 **Smart** - Learns your habits
- 🔧 **Drop-in replacement** - Works like cd
- 📊 **Accurate** - Uses frecency algorithm (frequency + recency)

Enjoy your smarter navigation! 🚀
