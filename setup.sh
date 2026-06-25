#!/usr/bin/env bash
# setup.sh — bootstrap shell config on a new machine
# Run once: bash setup.sh

set -e

DOTFILES_DIR="$HOME/.dotfiles"
SHELLRC="$DOTFILES_DIR/shellrc"
LOCAL_TEMPLATE="$DOTFILES_DIR/shellrc.local.template"
LOCAL_FILE="$HOME/.shellrc.local"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${CYAN}Setting up shell configuration...${RESET}"

# ============================================================
# Shell configuration
# ============================================================

echo -e "${YELLOW}[1/4] Setting up shellrc configuration...${RESET}"

# create shellrc.local if it doesn't exist
if [ ! -f "$LOCAL_FILE" ]; then
    echo "  Creating $LOCAL_FILE from template"
    cp "$LOCAL_TEMPLATE" "$LOCAL_FILE"
    echo -e "  ${GREEN}✓${RESET} - Created $LOCAL_FILE from template. You can edit this file to customize your shell configuration."
else
    echo -e "  ${GREEN}✓${RESET} - $LOCAL_FILE already exists — skipping"
fi

#Source shellrc in .zshrc or .bashrc
if [-f "$HOME/.zshrc"]; then
    if ! grep -q "source $SHELLRC" "$HOME/.zshrc"; then
        echo "  Adding source $SHELLRC to .zshrc"
        echo "source $SHELLRC" >> "$HOME/.zshrc"
        echo -e "  ${GREEN}✓${RESET} - Added source $SHELLRC to .zshrc"
    else
        echo -e "  ${GREEN}✓${RESET} - $SHELLRC already sourced in .zshrc — skipping"
    fi
fi

if [-f "$HOME/.bashrc"]; then
    if ! grep -q "source $SHELLRC" "$HOME/.bashrc"; then
        echo "  Adding source $SHELLRC to .bashrc"
        echo "source $SHELLRC" >> "$HOME/.bashrc"
        echo -e "  ${GREEN}✓${RESET} - Added source $SHELLRC to .bashrc"
    else
        echo -e "  ${GREEN}✓${RESET} - $SHELLRC already sourced in .bashrc — skipping"
    fi
fi

# ============================================================
# Neovim Configuration
# ============================================================
echo -e "${YELLOW}[2/4] Setting up Neovim configuration...${RESET}"
if [-d $DOTFILES_DIR/nvim]; then
    mkdir -p "$HOME/.config"

    # backup existing nvim config if it exists and is not a symlink
    if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up existing nvim config to $BACKUP_DIR"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
    fi

    # remove existing symlink if it exists
    if [ -L "$HOME/.config/nvim" ]; then
        echo "  Removing existing symlink for nvim config"
        rm "$HOME/.config/nvim"
    fi
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    echo -e "  ${GREEN}✓${RESET} - Neovim configuration set up successfully."
else
    echo -e "  ${YELLOW}⚠${RESET} - Neovim configuration directory $DOTFILES_DIR/nvim does not exist. Skipping Neovim setup."
fi

# ============================================================
# Tmux Configuration
# ============================================================
echo -e "${YELLOW}[3/4] Setting up Tmux configuration...${RESET}"

if [ ! -d "$DOTFILES_DIR/tmux" ]; then
    echo -e "  ${YELLOW}⚠${RESET} - Tmux configuration directory $DOTFILES_DIR/tmux does not exist. Skipping Tmux setup."
else
    # Backup existing tmux config if it exists and is not a symlink
    if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        BACKUP_FILE="$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up existing tmux config to $BACKUP_FILE"
        mv "$HOME/.tmux.conf" "$BACKUP_FILE"
    fi  
    # Remove existing symlink if it exists
    if [ -L "$HOME/.tmux.conf" ]; then
        echo "  Removing existing symlink for tmux config"
        rm "$HOME/.tmux.conf"
    fi
    ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo -e "  ${GREEN}✓${RESET} - Tmux configuration set up successfully."
fi  

# ============================================================
# Git Configuration
# ============================================================
echo -e "${YELLOW}[4/4] Setting up Git configuration...${RESET}"
if [ ! -d "$DOTFILES_DIR/git" ]; then
    echo -e "  ${YELLOW}⚠${RESET} - Git configuration directory $DOTFILES_DIR/git does not exist. Skipping Git setup."
else
    # Backup existing git config if it exists and is not a symlink
    if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
        BACKUP_FILE="$HOME/.gitconfig.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up existing git config to $BACKUP_FILE"
        mv "$HOME/.gitconfig" "$BACKUP_FILE"
    fi
    # Remove existing symlink if it exists
    if [ -L "$HOME/.gitconfig" ]; then
        echo "  Removing existing symlink for git config"
        rm "$HOME/.gitconfig"
    fi
    ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
    echo -e "  ${GREEN}✓${RESET} - Git configuration set up successfully."
fi

# ============================================================
# Dependency Check
# ============================================================
echo -e "${YELLOW}Checking for required dependencies...${RESET}"
DEPENDENCIES=(git zsh tmux nvim)
for dep in "${DEPENDENCIES[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${RESET} - $dep is installed"
    else
        local install_name="$dep"
        if [ "$dep" = "nvim" ]; then
            install_name="neovim"
        fi
        echo -e "  ${YELLOW}⚠${RESET} - $dep is not installed."
        echo "    Install with: brew install $install_name (macos) or sudo apt install $install_name (linux)"
    fi


# check for ls color support
if ls --version >/dev/null | grep -q "GNU"; then
    echo -e "  ${GREEN}✓${RESET} - ls supports color"
elif gls --version >/dev/null | grep -q "GNU"; then
    echo -e "  ${GREEN}✓${RESET} - ls (GNU ls) supports color"
else
    echo -e "  ${YELLOW}⚠${RESET} - GNU coreutils (ls) is not installed. Install with: brew install coreutils (macOS) or sudo apt install coreutils (Linux)"
fi

# ============================================================
# Final message
# ============================================================
echo -e "\n${GREEN}Shell configuration setup complete!${RESET}"
if [ -f "$HOME/.zshrc" ]; then 
    source "$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

if command -v tmux >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf"
fi

echo -e "\nNext steps:"
echo -e "1. Review and edit $LOCAL_FILE to customize your shell configuration."
echo -e "2. Restart your terminal or run 'source ~/.zshrc' or 'source ~/.bashrc' to apply the changes."
echo -e "3. Reload your tmux configuration with 'tmux source-file ~/.tmux.conf' if you use tmux."
echo -e "4. Open Neovim and run ':PlugInstall' to install plugins if you use vim-plug."




