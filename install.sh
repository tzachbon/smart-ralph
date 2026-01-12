#!/usr/bin/env bash
#
# ralph-specum installer
# Installs the ralph-specum CLI tool globally using Bun
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Symbols
CHECK="${GREEN}✔${NC}"
CROSS="${RED}✖${NC}"
ARROW="${CYAN}→${NC}"
INFO="${BLUE}ℹ${NC}"

# Installation paths
INSTALL_DIR="${HOME}/.ralph-specum"
BIN_DIR="${HOME}/.local/bin"

echo -e "\n${BOLD}${CYAN}ralph-specum${NC} installer\n"

# Check for Bun
check_bun() {
    if command -v bun &> /dev/null; then
        BUN_VERSION=$(bun --version)
        echo -e "${CHECK} Bun found: v${BUN_VERSION}"
        return 0
    else
        echo -e "${CROSS} Bun not found"
        return 1
    fi
}

# Install Bun if not present
install_bun() {
    echo -e "${ARROW} Installing Bun..."
    curl -fsSL https://bun.sh/install | bash

    # Source the new PATH
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    if command -v bun &> /dev/null; then
        echo -e "${CHECK} Bun installed successfully"
        return 0
    else
        echo -e "${CROSS} Failed to install Bun"
        return 1
    fi
}

# Check for Claude Code
check_claude() {
    if command -v claude &> /dev/null; then
        echo -e "${CHECK} Claude Code CLI found"
        return 0
    else
        echo -e "${YELLOW}⚠${NC}  Claude Code CLI not found (optional)"
        echo -e "   ${INFO} Install from: https://claude.ai/code"
        return 0
    fi
}

# Check for gh CLI
check_gh() {
    if command -v gh &> /dev/null; then
        echo -e "${CHECK} GitHub CLI found"
        return 0
    else
        echo -e "${YELLOW}⚠${NC}  GitHub CLI not found (optional)"
        echo -e "   ${INFO} Install from: https://cli.github.com"
        return 0
    fi
}

# Get script directory
get_script_dir() {
    # Handle different ways the script might be run
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        SCRIPT_DIR="$(pwd)"
    fi
    echo "${SCRIPT_DIR}"
}

# Install ralph-specum
install_ralph_specum() {
    SCRIPT_DIR=$(get_script_dir)

    echo -e "\n${ARROW} Installing ralph-specum...\n"

    # Create installation directory
    mkdir -p "${INSTALL_DIR}"
    mkdir -p "${BIN_DIR}"

    # Copy files to installation directory
    echo -e "   Copying files to ${INSTALL_DIR}..."
    cp -r "${SCRIPT_DIR}/cli" "${INSTALL_DIR}/"
    cp -r "${SCRIPT_DIR}/agents" "${INSTALL_DIR}/"
    cp -r "${SCRIPT_DIR}/templates" "${INSTALL_DIR}/"

    # Create symlink to executable
    echo -e "   Creating symlink..."
    chmod +x "${INSTALL_DIR}/cli/bin/ralph-specum"
    ln -sf "${INSTALL_DIR}/cli/bin/ralph-specum" "${BIN_DIR}/ralph-specum"

    # Add bin directory to PATH if not already there
    if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
        echo -e "\n${INFO} Adding ${BIN_DIR} to PATH..."

        # Detect shell and add to appropriate config
        SHELL_NAME=$(basename "$SHELL")
        case "$SHELL_NAME" in
            bash)
                echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "${HOME}/.bashrc"
                echo -e "   Added to ~/.bashrc"
                ;;
            zsh)
                echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "${HOME}/.zshrc"
                echo -e "   Added to ~/.zshrc"
                ;;
            fish)
                fish -c "set -U fish_user_paths ${BIN_DIR} \$fish_user_paths"
                echo -e "   Added to fish user paths"
                ;;
            *)
                echo -e "${YELLOW}⚠${NC}  Please add ${BIN_DIR} to your PATH manually"
                ;;
        esac

        export PATH="${BIN_DIR}:$PATH"
    fi

    echo -e "\n${CHECK} ralph-specum installed successfully!\n"
}

# Verify installation
verify_installation() {
    echo -e "${ARROW} Verifying installation...\n"

    if command -v ralph-specum &> /dev/null; then
        echo -e "${CHECK} ralph-specum is available in PATH"
        echo -e "\n${BOLD}Version:${NC}"
        ralph-specum --version
        return 0
    else
        echo -e "${CROSS} ralph-specum not found in PATH"
        echo -e "   ${INFO} Try restarting your terminal or run:"
        echo -e "   export PATH=\"${BIN_DIR}:\$PATH\""
        return 1
    fi
}

# Show usage
show_usage() {
    echo -e "\n${BOLD}Quick Start:${NC}"
    echo -e "  ralph-specum \"your goal description\""
    echo -e ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ralph-specum \"Add user authentication\""
    echo -e "  ralph-specum \"Create REST API for products\" --mode auto"
    echo -e "  ralph-specum status"
    echo -e "  ralph-specum help"
    echo -e ""
    echo -e "${BOLD}Documentation:${NC}"
    echo -e "  https://github.com/tzachbon/ralph-specum"
    echo -e ""
}

# Main installation flow
main() {
    echo -e "${BOLD}Checking dependencies...${NC}\n"

    # Check/install Bun
    if ! check_bun; then
        read -p "Would you like to install Bun? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            install_bun || exit 1
        else
            echo -e "${CROSS} Bun is required. Aborting."
            exit 1
        fi
    fi

    # Check optional dependencies
    check_claude
    check_gh

    # Install ralph-specum
    install_ralph_specum

    # Verify
    verify_installation

    # Show usage
    show_usage
}

# Handle arguments
case "${1:-}" in
    --uninstall|-u)
        echo -e "${ARROW} Uninstalling ralph-specum..."
        rm -rf "${INSTALL_DIR}"
        rm -f "${BIN_DIR}/ralph-specum"
        echo -e "${CHECK} ralph-specum uninstalled"
        exit 0
        ;;
    --help|-h)
        echo "Usage: ./install.sh [options]"
        echo ""
        echo "Options:"
        echo "  --uninstall, -u    Uninstall ralph-specum"
        echo "  --help, -h         Show this help"
        exit 0
        ;;
    *)
        main
        ;;
esac
