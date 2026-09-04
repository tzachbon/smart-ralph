#!/bin/bash
set -e

REPO="tzachbon/smart-ralph-mcp-server"
BINARY_NAME="ralph-specum-mcp"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

case "$OS" in
  darwin|linux) ;;
  mingw*|msys*|cygwin*) OS="windows" ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Get latest release
LATEST=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep tag_name | cut -d'"' -f4)
ASSET="${BINARY_NAME}-${OS}-${ARCH}"
[[ "$OS" == "windows" ]] && ASSET="${ASSET}.exe"

# Download and install
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
echo "Installing $BINARY_NAME $LATEST to $INSTALL_DIR..."

curl -fsSL "https://github.com/$REPO/releases/download/$LATEST/$ASSET" -o "/tmp/$BINARY_NAME"
chmod +x "/tmp/$BINARY_NAME"
sudo mv "/tmp/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"

echo "Installed! Add to your MCP client config:"
echo ""
echo '  "ralph-specum": {'
echo "    \"command\": \"$INSTALL_DIR/$BINARY_NAME\""
echo '  }'
