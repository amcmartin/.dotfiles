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

echo -e "${YELLOW}[1/5] Setting up shellrc configuration...${RESET}"

# create shellrc.local if it doesn't exist
if [ ! -f "$LOCAL_FILE" ]; then
    echo "  Creating $LOCAL_FILE from template"
    cp "$LOCAL_TEMPLATE" "$LOCAL_FILE"
    echo -e "  ${GREEN}✓${RESET} - Created $LOCAL_FILE from template. You can edit this file to customize your shell configuration."
else
    echo -e "  ${GREEN}✓${RESET} - $LOCAL_FILE already exists — skipping"
fi

# Source shellrc from the interactive rc file (.zshrc / .bashrc).
# A fresh macOS install has no ~/.zshrc (only a ~/.zprofile from Homebrew),
# so create the rc file for the user's login shell if it doesn't exist.
# .zprofile is left alone: it only runs for login shells and is where
# Homebrew's `brew shellenv` belongs.
add_source_line() {
    rc="$1"
    touch "$rc"
    if ! grep -qF "$SHELLRC" "$rc"; then
        printf '\n# dotfiles shellrc\n[ -f "%s" ] && source "%s"\n' "$SHELLRC" "$SHELLRC" >> "$rc"
        echo -e "  ${GREEN}✓${RESET} - Added shellrc to $rc"
    else
        echo -e "  ${GREEN}✓${RESET} - shellrc already sourced in $rc — skipping"
    fi
}

# Set up the login shell's rc file (created if missing), plus any other
# rc file that already exists
LOGIN_SHELL="$(basename "${SHELL:-}")"
for _shell in zsh bash; do
    _rc="$HOME/.${_shell}rc"
    if [ "$LOGIN_SHELL" = "$_shell" ] || [ -f "$_rc" ]; then
        add_source_line "$_rc"
    fi
done

# macOS bash login shells read .bash_profile, not .bashrc
if [ -f "$HOME/.bashrc" ] && [ "$(uname)" = "Darwin" ]; then
    touch "$HOME/.bash_profile"
    if ! grep -qF '.bashrc' "$HOME/.bash_profile"; then
        printf '\n# source .bashrc for login shells\n[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"\n' >> "$HOME/.bash_profile"
        echo -e "  ${GREEN}✓${RESET} - Added .bashrc sourcing to ~/.bash_profile"
    fi
fi

# ============================================================
# Neovim Configuration
# ============================================================
echo -e "${YELLOW}[2/5] Setting up Neovim configuration...${RESET}"
if [ -d $DOTFILES_DIR/nvim ]; then
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
echo -e "${YELLOW}[3/5] Setting up Tmux configuration...${RESET}"

if [ ! -f "$DOTFILES_DIR/tmux.conf" ]; then
    echo -e "  ${YELLOW}⚠${RESET} - Tmux configuration file $DOTFILES_DIR/tmux.conf does not exist. Skipping Tmux setup."
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
echo -e "${YELLOW}[4/5] Setting up Git configuration...${RESET}"
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
    echo -e "  ${GREEN}✓${RESET} - Git configuration symlinked successfully."

    # create gitconfig.local from template if it doesn't exist
    GITLOCAL_TEMPLATE="$DOTFILES_DIR/git/gitconfig.local.template"
    GITLOCAL_FILE="$HOME/.gitconfig.local"
    if [ ! -f "$GITLOCAL_FILE" ]; then
        echo "  Creating $GITLOCAL_FILE from template"
        cp "$GITLOCAL_TEMPLATE" "$GITLOCAL_FILE"
        echo -e "  ${GREEN}✓${RESET} - Created $GITLOCAL_FILE — fill in your name, email, and any secrets."
    else
        echo -e "  ${GREEN}✓${RESET} - $GITLOCAL_FILE already exists — skipping"
    fi
fi

# ============================================================
# Ghostty Configuration
# ============================================================
echo -e "${YELLOW}[5/5] Setting up Ghostty configuration...${RESET}"

if command -v ghostty >/dev/null 2>&1; then
    GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
    GHOSTTY_CONFIG="$GHOSTTY_CONFIG_DIR/config"
    mkdir -p "$GHOSTTY_CONFIG_DIR"

    # Backup existing ghostty config if it exists and is not a symlink
    if [ -e "$GHOSTTY_CONFIG" ] && [ ! -L "$GHOSTTY_CONFIG" ]; then
        BACKUP_FILE="$GHOSTTY_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up existing ghostty config to $BACKUP_FILE"
        mv "$GHOSTTY_CONFIG" "$BACKUP_FILE"
    fi

    # Remove existing symlink if it exists
    if [ -L "$GHOSTTY_CONFIG" ]; then
        echo "  Removing existing symlink for ghostty config"
        rm "$GHOSTTY_CONFIG"
    fi

    ln -sf "$DOTFILES_DIR/ghostty/config" "$GHOSTTY_CONFIG"
    echo -e "  ${GREEN}✓${RESET} - Ghostty configuration symlinked successfully."
else
    echo -e "  ${YELLOW}⚠${RESET} - Ghostty is not installed — skipping Ghostty setup."
fi

# ============================================================
# Git hooks
# ============================================================
echo -e "${YELLOW}Installing git hooks...${RESET}"
HOOKS_SRC="$DOTFILES_DIR/hooks"
HOOKS_DEST="$DOTFILES_DIR/.git/hooks"
if [ -d "$HOOKS_SRC" ] && [ -d "$HOOKS_DEST" ]; then
    for hook in "$HOOKS_SRC"/*; do
        hook_name=$(basename "$hook")
        ln -sf "$hook" "$HOOKS_DEST/$hook_name"
        chmod +x "$hook"
        echo -e "  ${GREEN}✓${RESET} - Installed $hook_name hook"
    done
else
    echo -e "  ${YELLOW}⚠${RESET} - hooks directory or .git/hooks not found — skipping"
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
        install_name="$dep"
        if [ "$dep" = "nvim" ]; then
            install_name="neovim"
        fi
        echo -e "  ${YELLOW}⚠${RESET} - $dep is not installed."
        echo "    Install with: brew install $install_name (macos) or sudo apt install $install_name (linux)"
    fi
done


# check for ls color support
if ls --version 2>/dev/null | grep -q "GNU"; then
    echo -e "  ${GREEN}✓${RESET} - ls supports color"
elif gls --version 2>/dev/null | grep -q "GNU"; then
    echo -e "  ${GREEN}✓${RESET} - ls (GNU ls) supports color"
else
    echo -e "  ${YELLOW}⚠${RESET} - GNU coreutils (ls) is not installed. Install with: brew install coreutils (macOS) or sudo apt install coreutils (Linux)"
fi

# ============================================================
# Final message
# ============================================================
echo -e "\n${GREEN}Shell configuration setup complete!${RESET}"

echo -e "\nNext steps:"
echo -e "1. Review and edit $LOCAL_FILE to customize your shell configuration."
echo -e "2. Restart your terminal or run 'exec \$SHELL -l' to apply the changes."
echo -e "3. Reload your tmux configuration with 'tmux source-file ~/.tmux.conf' if you use tmux."
echo -e "4. Open Neovim and run ':PlugInstall' to install plugins if you use vim-plug."