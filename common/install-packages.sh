#!/usr/bin/env bash

# Common package installation script for both macOS and Linux
# Uses Homebrew as the unified package manager

set -e

echo "=================================="
echo "Common Package Installation"
echo "=================================="
echo ""

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
echo "Detected OS: $OS"
echo ""

# Function to show loading spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  %s\r" "$spinstr" "$2"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r\033[K"  # Clear the entire line
}

# Function to run command with spinner
install_with_spinner() {
    local message="$1"
    local command="$2"
    
    eval "$command" > /tmp/install_output_$$.log 2>&1 &
    local pid=$!
    show_spinner $pid "$message"
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf " [✓]  %s\n" "$message"
    else
        printf " [✗]  %s (Failed!)\n" "$message"
        echo "Error log:"
        cat /tmp/install_output_$$.log
        rm -f /tmp/install_output_$$.log
        return $exit_code
    fi
    rm -f /tmp/install_output_$$.log
}

# Install build dependencies for Homebrew on Linux
install_linux_build_deps() {
    if [[ "$OS" != "linux" ]]; then
        return 0
    fi
    
    echo ""
    echo "Installing build dependencies for Homebrew..."
    
    # Detect package manager and install build tools
    if command -v apt-get &> /dev/null; then
        install_with_spinner "Installing build tools (Debian/Ubuntu)" "sudo apt-get update && sudo apt-get install -y build-essential procps curl file git"
    elif command -v dnf &> /dev/null; then
        # Check if Fedora or CentOS/RHEL
        if grep -qi fedora /etc/os-release 2>/dev/null; then
            install_with_spinner "Installing build tools (Fedora)" "sudo dnf groupinstall -y 'Development Tools' && sudo dnf install -y procps-ng curl file git"
        else
            install_with_spinner "Installing build tools (CentOS/RHEL)" "sudo dnf groupinstall -y 'Development Tools' && sudo dnf install -y procps-ng curl file git"
        fi
    elif command -v yum &> /dev/null; then
        install_with_spinner "Installing build tools (CentOS/RHEL)" "sudo yum groupinstall -y 'Development Tools' && sudo yum install -y procps-ng curl file git"
    elif command -v pacman &> /dev/null; then
        install_with_spinner "Installing build tools (Arch Linux)" "sudo pacman -S --noconfirm base-devel procps-ng curl file git"
    else
        echo " [!]  Could not detect package manager. Please install build tools manually."
        echo "      See: https://docs.brew.sh/Homebrew-on-Linux#requirements"
    fi
}

# Install Homebrew if not already installed
install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo " [✓]  Homebrew is already installed"
    else
        # Install build dependencies on Linux first
        if [[ "$OS" == "linux" ]]; then
            install_linux_build_deps
        fi
        
        echo ""
        echo " [ ]  Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH based on OS
        if [[ "$OS" == "linux" ]]; then
            # Check both possible Linux locations
            local brew_shellenv=""
            if [ -d "$HOME/.linuxbrew" ]; then
                brew_shellenv='eval "$($HOME/.linuxbrew/bin/brew shellenv)"'
            elif [ -d "/home/linuxbrew/.linuxbrew" ]; then
                brew_shellenv='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
            fi
            
            if [ -n "$brew_shellenv" ]; then
                # Add to .zshrc (not .zprofile) as per Homebrew docs
                if ! grep -q "brew shellenv" ~/.zshrc 2>/dev/null; then
                    echo "" >> ~/.zshrc
                    echo "# Homebrew" >> ~/.zshrc
                    echo "$brew_shellenv" >> ~/.zshrc
                fi
                eval "$brew_shellenv"
            fi
        elif [[ "$OS" == "macos" ]]; then
            # For Apple Silicon
            if [[ -d "/opt/homebrew" ]]; then
                if ! grep -q "brew shellenv" ~/.zshrc 2>/dev/null; then
                    echo "" >> ~/.zshrc
                    echo "# Homebrew" >> ~/.zshrc
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
                fi
                eval "$(/opt/homebrew/bin/brew shellenv)"
            # For Intel
            elif [[ -d "/usr/local/Homebrew" ]]; then
                if ! grep -q "brew shellenv" ~/.zshrc 2>/dev/null; then
                    echo "" >> ~/.zshrc
                    echo "# Homebrew" >> ~/.zshrc
                    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
                fi
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        echo " [✓]  Homebrew installed successfully"
    fi
}

# Install common CLI tools via Homebrew
install_common_tools() {
    echo ""
    echo "Installing common CLI tools..."
    
    # Core utilities
    local tools=(
        "curl"
        "wget"
        "git"
        "git-lfs"
        "zsh"
        "tmux"
        "neovim"
        "ripgrep"
        "tree"
        "htop"
        "mise"
    )
    
    for tool in "${tools[@]}"; do
        if brew list "$tool" &>/dev/null; then
            echo " [✓]  $tool (already installed)"
        else
            install_with_spinner "Installing $tool" "brew install $tool"
        fi
    done
}

# Setup ZSH
setup_zsh() {
    echo ""
    echo "Setting up ZSH..."
    
    if command -v zsh >/dev/null 2>&1; then
        echo " [✓]  ZSH is already installed"
    else
        install_with_spinner "Installing ZSH" "brew install zsh"
    fi
    
    # Check if zsh is the default shell
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ] && [[ "$SHELL" != *"homebrew"*"zsh"* ]] && [[ "$SHELL" != *"linuxbrew"*"zsh"* ]]; then
        local zsh_path=$(which zsh)
        
        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            echo " [ ]  Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        
        install_with_spinner "Setting ZSH as default shell" "sudo chsh -s $zsh_path $USER"
        touch ~/.zshrc
        echo ""
        echo "⚠️  ZSH has been set as your default shell."
        echo "    Please log out and log back in for this to take effect."
    else
        echo " [✓]  ZSH is already the default shell"
    fi
}

# Setup Prezto
setup_prezto() {
    echo ""
    echo "Setting up Prezto..."
    
    if [ -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
        echo " [✓]  Prezto is already installed"
    else
        install_with_spinner "Installing Prezto" "git clone --recursive https://github.com/sorin-ionescu/prezto.git \"${ZDOTDIR:-$HOME}/.zprezto\""
    fi
    
    # Add Prezto configuration to .zshrc
    local zshrc_file="${ZDOTDIR:-$HOME}/.zshrc"
    local prezto_config='
# Source Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi'
    
    if ! grep -q "zprezto/init.zsh" "$zshrc_file" 2>/dev/null; then
        echo "$prezto_config" >> "$zshrc_file"
        echo " [✓]  Prezto configuration added to .zshrc"
    else
        echo " [✓]  Prezto configuration already exists in .zshrc"
    fi
}

# Setup Starship
setup_starship() {
    echo ""
    echo "Setting up Starship..."
    
    if command -v starship >/dev/null 2>&1; then
        echo " [✓]  Starship is already installed"
    else
        printf " [ ]  Installing Starship..."
        if curl -sS https://starship.rs/install.sh | sh -s -- --yes > /tmp/starship_install_$$.log 2>&1; then
            printf "\r [✓]  Installing Starship\n"
        else
            printf "\r [✗]  Installing Starship (Failed!)\n"
            cat /tmp/starship_install_$$.log
            rm -f /tmp/starship_install_$$.log
            return 1
        fi
        rm -f /tmp/starship_install_$$.log
    fi

    # Add Starship configuration to .zshrc
    local zshrc_file="${ZDOTDIR:-$HOME}/.zshrc"
    local starship_config='
# Initialize Starship prompt
eval "$(starship init zsh)"'
    
    if ! grep -q "starship init zsh" "$zshrc_file" 2>/dev/null; then
        echo "$starship_config" >> "$zshrc_file"
        echo " [✓]  Starship configuration added to .zshrc"
    else
        echo " [✓]  Starship configuration already exists in .zshrc"
    fi
}

# Main installation flow
main() {
    install_homebrew
    install_common_tools
    setup_zsh
    setup_prezto
    setup_starship
    
    echo ""
    echo "=================================="
    echo "Package installation complete!"
    echo "=================================="
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. If ZSH was just set as default, log out and log back in"
    echo "  3. Enjoy your new shell setup with Prezto and Starship!"
    echo ""
}

# Run main installation
main