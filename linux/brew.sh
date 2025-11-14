#!/usr/bin/env bash

cd $(dirname $BASH_SOURCE);

# Install command-line tools using Homebrew on Linux.
# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Linux
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Make sure we're using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew's installed location.
BREW_PREFIX=$(brew --prefix)

brew install jq
brew install uv

# Add your Linux-specific packages here
# Example:
# brew install git
# brew install vim
# brew install wget
# brew install curl

# Remove outdated versions from the cellar.
brew cleanup

