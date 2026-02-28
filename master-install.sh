#!/bin/bash
################################################################################
# MASTER INSTALLER - Complete Sway Setup for Debian
# This script orchestrates all installation steps
# For Intel i5-6500T (HD 530 iGPU) systems
################################################################################

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script names
SOURCES_SCRIPT="sources_list_setup.sh"
MAIN_SCRIPT="sway-minimal-install.sh"
TWEAKS_SCRIPT="sway-post-install-tweaks.sh"
DEPLOY_SCRIPT="deploy-configs.sh"
GAMING_SCRIPT="setup-gaming-env.sh"

echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║               SWAY MINIMAL SETUP - MASTER INSTALLER                       ║
║                                                                           ║
║  Target: Intel i5-6500T (HD 530 iGPU) | Debian 13+                       ║
║  Goal: <200MB idle RAM, tear-free Wayland                                ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Root check
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Usage: sudo bash $0"
    exit 1
fi

# Detect or ask for user
user=$(logname 2>/dev/null || echo "$SUDO_USER")
if [ -z "$user" ] || [ "$user" = "root" ]; then
    read -p "Enter username to configure: " user
fi

echo ""
echo -e "${GREEN}Installation will be performed for user: $user${NC}"
echo ""

# Confirmation
read -p "Continue with installation? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Store original directory before changing
ORIGINAL_DIR="$PWD"

# Create working directory
WORK_DIR="/tmp/sway-install-$(date +%s)"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo ""
echo -e "${YELLOW}Working directory: $WORK_DIR${NC}"
echo ""

################################################################################
# STEP 1: Download Scripts
################################################################################
echo -e "${BLUE}[1/4] Locating installation scripts...${NC}"

# Function to find and copy a script
find_and_copy_script() {
    local script_name="$1"
    
    # Check in same directory as master script
    if [ -f "$SCRIPT_DIR/$script_name" ]; then
        cp "$SCRIPT_DIR/$script_name" .
        echo "✓ Found $script_name in script directory"
        return 0
    # Check in /tmp/
    elif [ -f "/tmp/$script_name" ]; then
        cp "/tmp/$script_name" .
        echo "✓ Found $script_name in /tmp/"
        return 0
    # Check in original directory
    elif [ -f "$ORIGINAL_DIR/$script_name" ]; then
        cp "$ORIGINAL_DIR/$script_name" .
        echo "✓ Found $script_name in original directory"
        return 0
    fi
    
    return 1
}

# Function to find and copy a directory (e.g. config-files/)
find_and_copy_dir() {
    local dir_name="$1"
    
    if [ -d "$SCRIPT_DIR/$dir_name" ]; then
        cp -r "$SCRIPT_DIR/$dir_name" .
        echo "✓ Found $dir_name/ in script directory"
        return 0
    elif [ -d "$ORIGINAL_DIR/$dir_name" ]; then
        cp -r "$ORIGINAL_DIR/$dir_name" .
        echo "✓ Found $dir_name/ in original directory"
        return 0
    fi
    
    return 1
}

# Try to find each script
find_and_copy_script "$SOURCES_SCRIPT" || echo "Note: $SOURCES_SCRIPT will be embedded"
find_and_copy_script "$MAIN_SCRIPT"    || echo "Warning: $MAIN_SCRIPT not found locally"
find_and_copy_script "$TWEAKS_SCRIPT"  || echo "Note: $TWEAKS_SCRIPT not available"
find_and_copy_script "$DEPLOY_SCRIPT"  || echo "Note: $DEPLOY_SCRIPT not found (configs will use fallbacks)"
find_and_copy_script "$GAMING_SCRIPT"  || echo "Note: $GAMING_SCRIPT not found (gaming setup will be skipped)"
find_and_copy_dir "config-files"       || echo "Note: config-files/ not found (configs will use fallbacks)"

################################################################################
# STEP 2: Setup Debian Repositories
################################################################################
echo ""
echo -e "${BLUE}[2/4] Setting up Debian repositories...${NC}"
echo ""

read -p "Setup Debian repositories (adds contrib/non-free)? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "$SOURCES_SCRIPT" ]; then
        chmod +x "$SOURCES_SCRIPT"
        bash "$SOURCES_SCRIPT"
    else
        # Inline sources setup
        echo "Configuring sources.list..."
        cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d-%H%M%S)
        
        DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
        case "$DEBIAN_VERSION" in
            13) CODENAME="trixie" ;;
            12) CODENAME="bookworm" ;;
            11) CODENAME="bullseye" ;;
            *) CODENAME="trixie" ;;
        esac
        
        cat > /etc/apt/sources.list << EOSOURCES
deb http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware
EOSOURCES
        
        apt update -qq
        echo -e "${GREEN}✓ Sources configured for $CODENAME${NC}"
    fi
else
    echo "Skipping sources setup..."
fi

################################################################################
# STEP 3: Main Sway Installation
################################################################################
echo ""
echo -e "${BLUE}[3/4] Installing Sway environment...${NC}"
echo ""

read -p "Proceed with Sway installation? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "$MAIN_SCRIPT" ]; then
        chmod +x "$MAIN_SCRIPT"
        USER="$user" bash "$MAIN_SCRIPT"
    else
        echo -e "${RED}ERROR: $MAIN_SCRIPT not found${NC}"
        echo "Please ensure the script is available in:"
        echo "  - Same directory as master-install.sh ($SCRIPT_DIR)"
        echo "  - /tmp/ directory"
        echo "  - Current directory"
        exit 1
    fi
else
    echo "Skipping main installation..."
    exit 0
fi

################################################################################
# STEP 4: Post-Install Tweaks (Optional)
################################################################################
echo ""
echo -e "${BLUE}[4/4] Post-installation tweaks...${NC}"
echo ""

read -p "Run post-install tweaks? (themes, apps, optimizations) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$TWEAKS_SCRIPT" ]; then
        chmod +x "$TWEAKS_SCRIPT"
        USER="$user" bash "$TWEAKS_SCRIPT"
    else
        echo -e "${YELLOW}Warning: $TWEAKS_SCRIPT not found${NC}"
        echo "Skipping optional tweaks..."
    fi
else
    echo "Skipping post-install tweaks..."
fi

################################################################################
# STEP 5: Gaming Environment Setup (Optional)
################################################################################
echo ""
echo -e "${BLUE}[5/5] Gaming environment setup (shader cache + gamemode)...${NC}"
echo ""

read -p "Set up gaming optimizations (shader cache dirs, /etc/environment, gamemode multiarch)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$GAMING_SCRIPT" ]; then
        chmod +x "$GAMING_SCRIPT"
        bash "$GAMING_SCRIPT"
    else
        echo -e "${YELLOW}Warning: $GAMING_SCRIPT not found, skipping gaming setup...${NC}"
    fi
else
    echo "Skipping gaming setup..."
fi

################################################################################
# COMPLETION
################################################################################
echo ""
echo -e "${GREEN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                    ✓ INSTALLATION COMPLETE!                              ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Review the installation log above for any errors"
echo "2. Reboot your system: ${GREEN}sudo systemctl reboot${NC}"
echo "3. Log in as '$user' on TTY1"
echo "4. Sway will auto-start"
echo ""
echo -e "${YELLOW}Quick Reference:${NC}"
echo "  • Super + Enter     = Terminal"
echo "  • Super + D         = App launcher"
echo "  • Super + Shift + S = Screenshot"
echo "  • Super + Shift + E = Exit Sway"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  • neofetch          = System info"
echo "  • htop              = Resource monitor"
echo "  • sensors           = Temperature"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  • README: /tmp/README.md"
echo "  • Quick Reference: /tmp/SWAY-QUICK-REFERENCE.md"
echo "  • GitHub: https://github.com/BeanGreen247/sway-setup-script"
echo ""

# Cleanup option
read -p "Remove installation scripts from $WORK_DIR? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd /tmp
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}✓ Cleanup complete${NC}"
else
    echo "Scripts preserved in: $WORK_DIR"
fi

echo ""
read -p "Reboot now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    systemctl reboot
else
    echo ""
    echo -e "${GREEN}Installation complete. Reboot when ready with: sudo systemctl reboot${NC}"
    echo ""
fi
