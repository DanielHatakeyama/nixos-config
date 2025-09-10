#!/usr/bin/env bash
# Kitty opacity management for neovim integration

# Function to set kitty opacity
set_kitty_opacity() {
    local opacity="$1"
    if [[ -n "$KITTY_WINDOW_ID" ]]; then
        kitty @ --to unix:/tmp/mykitty set-background-opacity "$opacity"
    fi
}

# Function to detect if neovim is running in current session
nvim_running() {
    pgrep -x nvim > /dev/null 2>&1
}

# Auto-adjust opacity based on neovim presence
auto_adjust_opacity() {
    if nvim_running; then
        set_kitty_opacity 1.0  # Opaque when nvim is running
    else
        set_kitty_opacity 0.7  # More transparent when nvim is not running
    fi
}

# Wrapper functions for neovim
nvim() {
    set_kitty_opacity 1.0  # Make opaque before starting nvim
    command nvim "$@"
    local exit_code=$?
    set_kitty_opacity 0.7  # Make more transparent after nvim exits
    return $exit_code
}

# Aliases for common neovim commands
alias vi='nvim'
alias vim='nvim'
