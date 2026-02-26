#!/bin/bash
################################################################################
# Debian sources.list Setup for Sway Installation
# Adds contrib and non-free repos needed for proprietary drivers/firmware
# Run this BEFORE the main sway-minimal-install.sh
################################################################################

set -e

if [ "$(id -u)" != "0" ]; then
    echo "Run as root: sudo bash $0"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "  Debian Sources Setup"
echo "════════════════════════════════════════════════════════"

# Clean up any existing Microsoft/VSCode repository configurations
echo "Cleaning up any existing third-party repository configurations..."
rm -f /usr/share/keyrings/packages.microsoft.gpg
rm -f /usr/share/keyrings/microsoft.gpg
rm -f /usr/share/keyrings/microsoft*.gpg
rm -f /etc/apt/sources.list.d/vscode.list*
rm -f /etc/apt/sources.list.d/microsoft*.list*
rm -f /etc/apt/sources.list.d/*vscode*
rm -f /etc/apt/sources.list.d/*microsoft*

# Backup existing sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d-%H%M%S)

# Detect Debian version
DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
case "$DEBIAN_VERSION" in
    13) CODENAME="trixie" ;;
    12) CODENAME="bookworm" ;;
    11) CODENAME="bullseye" ;;
    *) 
        echo "Unknown Debian version: $DEBIAN_VERSION"
        echo "Defaulting to trixie..."
        CODENAME="trixie"
        ;;
esac

echo "Detected Debian $CODENAME ($DEBIAN_VERSION)"

# Create new sources.list with main, contrib, non-free
cat > /etc/apt/sources.list << EOF
# Debian $CODENAME - Main repositories
deb http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware

# Security updates
deb http://deb.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware

# Updates
deb http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware

# Backports (optional - commented out by default)
# deb http://deb.debian.org/debian/ $CODENAME-backports main contrib non-free non-free-firmware
EOF

echo ""
echo "✓ Sources configured for: $CODENAME"
echo "✓ Enabled: main contrib non-free non-free-firmware"
echo ""
echo "Updating package lists..."
apt update

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✓ Sources setup complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Backup saved to: /etc/apt/sources.list.backup.*"
echo "You can now run: sudo bash sway-minimal-install.sh"
echo ""
