#!/bin/bash

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
    
    $command &
    local pid=$!
    show_spinner $pid "$message"
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf " [✓]  %s ✓ Done!\n" "$message"
    else
        printf " [✗]  %s ✗ Failed!\n" "$message"
        return $exit_code
    fi
}


# Setup ZSH
setup_zsh() {
    if command -v zsh >/dev/null 2>&1; then
        install_with_spinner "ZSH is already installed" "true"
    else
        install_with_spinner "Installing ZSH" "sudo apt install zsh -y"
    fi
    
    # Check if zsh is the default shell
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
        install_with_spinner "Setting ZSH as default shell" "sudo chsh -s $(which zsh)"
        touch ~/.zshrc
    else
        echo "✓ ZSH is already the default shell"
    fi
}

# Setup Prezto
setup_prezto() {
    if [ -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
        install_with_spinner "Prezto is already installed" "true"
    else
        install_with_spinner "Installing Prezto" "git clone --recursive https://github.com/sorin-ionescu/prezto.git \"${ZDOTDIR:-$HOME}/.zprezto\""
    fi
    
    # Add Prezto configuration to .zshrc
    local zshrc_file="${ZDOTDIR:-$HOME}/.zshrc"
    local prezto_config='if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi'
    
    if ! grep -q "zprezto/init.zsh" "$zshrc_file" 2>/dev/null; then
        echo "$prezto_config" >> "$zshrc_file"
    else
        echo "✓ Prezto configuration already exists in .zshrc"
    fi
}

# Setup Starship
setup_starship() {
    if command -v starship >/dev/null 2>&1; then
        install_with_spinner "Starship is already installed" "true"
    else
        printf " [ ]  Installing Starship"
        if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
            printf "\r [✓]  Installing Starship ✓ Done!\n"
        else
            printf "\r [✗]  Installing Starship ✗ Failed!\n"
            return 1
        fi
    fi

    # Add Starship configuration to .zshrc
    local zshrc_file="${ZDOTDIR:-$HOME}/.zshrc"
    local starship_config='eval "$(starship init zsh)"'
    
    if ! grep -q "starship/init.zsh" "$zshrc_file" 2>/dev/null; then
        echo "$starship_config" >> "$zshrc_file"
    else
        echo "✓ Starship configuration already exists in .zshrc"
    fi
}
# Run ZSH setup
setup_zsh

# Run Prezto setup
setup_prezto

# Run Starship setup
setup_starship

exec zsh