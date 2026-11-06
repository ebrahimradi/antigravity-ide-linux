#!/usr/bin/env bash
# Antigravity IDE Uninstaller
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Root privileges required. Elevating with sudo..."
  exec sudo bash "$0" "$@"
fi

echo "Removing Antigravity IDE and Updater..."
rm -rf /opt/antigravity-ide
rm -f /usr/local/bin/antigravity-ide
rm -f /usr/local/bin/update-antigravity-ide
rm -f /usr/share/applications/antigravity-ide.desktop
rm -f /usr/share/applications/update-antigravity-ide.desktop
rm -f /usr/share/icons/hicolor/512x512/apps/antigravity-ide.png
rm -f /etc/sudoers.d/antigravity-ide-updater

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi

echo "Antigravity IDE successfully removed from your system."

