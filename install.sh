#!/bin/bash

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Install common dotfiles
echo "Installing common dotfiles..."
DOTFILES_DIR="$(pwd)"
COMMON_DIR="$DOTFILES_DIR/common"

echo "Installing common packages..."
bash "$COMMON_DIR/install-packages.sh"

# Append OS-specific .zshrc content if it exists
if [[ "$OS" == "linux" ]]; then
    LINUX_DIR="$DOTFILES_DIR/linux"
    if [ -f "$LINUX_DIR/.zshrc" ]; then
        echo "" >> "$HOME/.zshrc"
        echo "# ============================================" >> "$HOME/.zshrc"
        echo "# Linux-specific configuration" >> "$HOME/.zshrc"
        echo "# ============================================" >> "$HOME/.zshrc"
        cat "$LINUX_DIR/.zshrc" >> "$HOME/.zshrc"
        echo "  Appended Linux-specific configuration"
    fi
elif [[ "$OS" == "macos" ]]; then
    MACOS_DIR="$DOTFILES_DIR/macos"
    if [ -f "$MACOS_DIR/.zshrc" ]; then
        echo "" >> "$HOME/.zshrc"
        echo "# ============================================" >> "$HOME/.zshrc"
        echo "# macOS-specific configuration" >> "$HOME/.zshrc"
        echo "# ============================================" >> "$HOME/.zshrc"
        cat "$MACOS_DIR/.zshrc" >> "$HOME/.zshrc"
        echo "  Appended macOS-specific configuration"
    fi
fi

# Install OS-specific dotfiles
if [[ "$OS" == "linux" ]]; then
    echo "Installing Linux-specific dotfiles..."
    LINUX_DIR="$DOTFILES_DIR/linux"
    # Additional Linux-specific dotfiles can be added here

    echo ""
    install_packages="y"

    if [[ "$install_packages" =~ ^[Yy]$ ]]; then
        echo "Installing additional Linux packages..."
        bash "$LINUX_DIR/brew.sh"
    else
        echo "Skipping additional Linux packages."
        echo "You can run it later with: bash $LINUX_DIR/brew.sh"
    fi

elif [[ "$OS" == "macos" ]]; then
    echo "Installing macOS-specific dotfiles..."
    MACOS_DIR="$DOTFILES_DIR/macos"

    echo ""
    install_packages="y"

    if [[ "$install_packages" =~ ^[Yy]$ ]]; then
        echo "Installing additional macOS packages..."
        bash "$MACOS_DIR/brew.sh"
    else
        echo "Skipping additional macOS packages."
        echo "You can run it later with: bash $MACOS_DIR/brew.sh"
    fi
fi


exec zsh