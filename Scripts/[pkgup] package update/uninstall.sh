#!/usr/bin/env bash
# ============================================
#   UNINSTALL PKGUP
#   Removes all pkgup files
# ============================================
set -euo pipefail

INSTALL_DIR="/usr/local/lib/pkgup"
BIN_DIR="/usr/local/bin"
COMMAND_NAME="pkgup"

echo "Uninstalling Package Update System..."

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# Remove main command
if [ -f "$BIN_DIR/$COMMAND_NAME" ]; then
    echo "Removing command: $BIN_DIR/$COMMAND_NAME"
    rm -f "$BIN_DIR/$COMMAND_NAME"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing directory: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi

# Remove related desktop files and logs (add more as modules are added)
echo "Removing associated application files..."
if [ -f "/usr/share/applications/discord.desktop" ]; then
    rm -f "/usr/share/applications/discord.desktop"
fi

if [ -f "/var/log/update-discord.log" ]; then
    rm -f "/var/log/update-discord.log"
fi

echo ""
echo "pkgup has been uninstalled."
echo "Note: This script does not remove the applications themselves (e.g., Discord), only the updater scripts."
