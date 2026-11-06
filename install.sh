#!/usr/bin/env bash
# ==============================================================================
# Antigravity IDE & Updater Installer for Ubuntu / Linux
#
# Resolves the latest official Google release dynamically from:
# https://antigravity.google/download
#
# Supports:
#   - x86_64 / amd64
#   - aarch64 / arm64
# ==============================================================================
set -euo pipefail

INSTALL_DIR="/opt/antigravity-ide"
BIN_DIR="/usr/local/bin"
DESKTOP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor/512x512/apps"
SUDOERS_FILE="/etc/sudoers.d/antigravity-ide-updater"

DOWNLOAD_PAGE="https://antigravity.google/download"
GITHUB_RAW="https://raw.githubusercontent.com/ebrahimradi/antigravity-ide-linux/main"

# Color helpers
info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()   { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2; exit 1; }

# Re-execute with sudo if not root
if [ "$(id -u)" -ne 0 ]; then
  info "Root privileges required for installation. Elevating with sudo..."
  exec sudo bash "$0" "$@"
fi

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)   AG_ARCH="linux-x64" ;;
  aarch64|arm64)  AG_ARCH="linux-arm" ;;
  *) err "Unsupported architecture: $ARCH. Only x86_64 and arm64 are supported." ;;
esac
info "Detected architecture: $ARCH ($AG_ARCH)"

# Ensure core dependencies
for cmd in curl tar python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    info "Installing missing dependency: $cmd..."
    apt-get update -qq && apt-get install -y -qq "$cmd"
  fi
done

# Resolve latest release from Google
info "Querying Google for the latest Antigravity IDE release..."
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

RESOLUTION=$(python3 - "$DOWNLOAD_PAGE" "$AG_ARCH" <<'PY'
import sys, urllib.request, re

page_url = sys.argv[1]
arch = sys.argv[2]

try:
    req = urllib.request.Request(page_url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        html = resp.read().decode('utf-8', errors='replace')
except Exception as e:
    sys.exit(f"Failed to query Google download page: {e}")

# Match Google CDN URLs for Antigravity IDE
pattern = rf'https://edgedl\.me\.gvt1\.com[^\s"\'<>]+/{re.escape(arch)}/Antigravity%20IDE\.tar\.gz'
matches = set(re.findall(pattern, html))

if not matches:
    sys.exit(f"Could not find download URL for {arch} in official Google release page.")

url = list(matches)[0]
m_ver = re.search(r'stable/(\d+\.\d+\.\d+)(?:-[^/]+)?/', url)
version = m_ver.group(1) if m_ver else "unknown"

print(f"{version} {url}")
PY
)

read -r LATEST_VERSION DOWNLOAD_URL <<< "$RESOLUTION"
info "Latest Google version: $LATEST_VERSION"

# Check if already up to date
VERSION_FILE="$INSTALL_DIR/.version"
if [ -f "$VERSION_FILE" ] && [ "$#" -eq 0 ]; then
  CURRENT_VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo "")"
  if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ -x "$INSTALL_DIR/Antigravity-IDE/antigravity-ide" ]; then
    ok "Antigravity IDE $CURRENT_VERSION is already up to date!"
    exit 0
  fi
fi

# Download official tarball
ARCHIVE="$TMPDIR/Antigravity-IDE.tar.gz"
info "Downloading Antigravity IDE $LATEST_VERSION from Google..."
curl -fL --progress-bar -o "$ARCHIVE" "$DOWNLOAD_URL"

# Extract and install
info "Installing to $INSTALL_DIR..."
mkdir -p "$TMPDIR/extracted"
tar -xzf "$ARCHIVE" -C "$TMPDIR/extracted"

EXTRACTED_DIR="$(find "$TMPDIR/extracted" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[ -d "$EXTRACTED_DIR" ] || err "Failed to extract archive."

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/Antigravity-IDE.old"
if [ -d "$INSTALL_DIR/Antigravity-IDE" ]; then
  mv "$INSTALL_DIR/Antigravity-IDE" "$INSTALL_DIR/Antigravity-IDE.old"
fi
mv "$EXTRACTED_DIR" "$INSTALL_DIR/Antigravity-IDE"
rm -rf "$INSTALL_DIR/Antigravity-IDE.old"

echo "$LATEST_VERSION" > "$INSTALL_DIR/.version"
echo "$DOWNLOAD_URL" > "$INSTALL_DIR/.source-url"

# Fix sandbox permissions if required
if [ -f "$INSTALL_DIR/Antigravity-IDE/chrome-sandbox" ]; then
  chown root:root "$INSTALL_DIR/Antigravity-IDE/chrome-sandbox"
  chmod 4755 "$INSTALL_DIR/Antigravity-IDE/chrome-sandbox"
fi

# CLI symlink
mkdir -p "$BIN_DIR"
ln -sfn "$INSTALL_DIR/Antigravity-IDE/antigravity-ide" "$BIN_DIR/antigravity-ide"

# Icon
mkdir -p "$ICON_DIR"
if [ -f "$INSTALL_DIR/Antigravity-IDE/resources/app/resources/linux/code.png" ]; then
  cp "$INSTALL_DIR/Antigravity-IDE/resources/app/resources/linux/code.png" "$ICON_DIR/antigravity-ide.png"
elif [ -f "assets/antigravity-ide.png" ]; then
  cp "assets/antigravity-ide.png" "$ICON_DIR/antigravity-ide.png"
fi

# Desktop launcher for IDE
mkdir -p "$DESKTOP_DIR"
cat <<'EOF' > "$DESKTOP_DIR/antigravity-ide.desktop"
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity IDE - AI-first Code Editor
Exec=/usr/local/bin/antigravity-ide %F
Icon=antigravity-ide
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=inode/directory;text/plain;application/x-code-workspace;application/x-antigravity-workspace;x-scheme-handler/antigravity-ide;
StartupNotify=true
StartupWMClass=antigravity-ide
EOF

# Updater binary
cat <<'EOF' > "$BIN_DIR/update-antigravity-ide"
#!/usr/bin/env bash
set -euo pipefail
echo "================================================="
echo "       Checking Antigravity IDE Updates          "
echo "================================================="
echo ""
SCRIPT_URL="https://raw.githubusercontent.com/ebrahimradi/antigravity-ide-linux/main/install.sh"
if [ "$(id -u)" -eq 0 ]; then
  curl -fsSL "$SCRIPT_URL" | bash -s -- --update
else
  curl -fsSL "$SCRIPT_URL" | sudo bash -s -- --update
fi
EOF
chmod 755 "$BIN_DIR/update-antigravity-ide"

# Desktop launcher for Updater
cat <<'EOF' > "$DESKTOP_DIR/update-antigravity-ide.desktop"
[Desktop Entry]
Name=Update Antigravity IDE
Comment=Check for and install Antigravity IDE updates
Exec=bash -c "/usr/local/bin/update-antigravity-ide; echo ''; read -n 1 -s -r -p 'Press any key to close...'"
Icon=antigravity-ide
Terminal=true
Type=Application
Categories=Development;IDE;
StartupNotify=true
EOF

# Passwordless sudo for updater
if [ -d "/etc/sudoers.d" ]; then
  cat <<'EOF' > "$SUDOERS_FILE"
ALL ALL=(ALL) NOPASSWD: /usr/local/bin/update-antigravity-ide
EOF
  chmod 0440 "$SUDOERS_FILE"
fi

# Refresh desktop caches
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
fi

ok "Successfully installed Antigravity IDE $LATEST_VERSION!"
echo ""
echo "Installed components:"
echo "  - Antigravity IDE:        $BIN_DIR/antigravity-ide"
echo "  - 1-Click Updater:         $BIN_DIR/update-antigravity-ide"
echo "  - Ubuntu Menu Launchers:   'Antigravity IDE' & 'Update Antigravity IDE'"
echo ""
echo "To update in the future, click 'Update Antigravity IDE' in your apps menu,"
echo "or run: update-antigravity-ide"

