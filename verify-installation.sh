#!/bin/bash
################################################################################
# Sway Installation Verification & System Check
# Run this AFTER installation to verify everything works correctly
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Helper functions
check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASS++))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAIL++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARN++))
}

section_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

# Title
clear
echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║           SWAY INSTALLATION VERIFICATION                      ║
║           System Health Check & Diagnostics                   ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

################################################################################
# 1. CORE PACKAGES
################################################################################
section_header "1. Core Package Installation"

packages=(
    "sway"
    "waybar"
    "foot"
    "wofi"
    "swaybg"
    "swayidle"
    "swaylock"
    "wl-clipboard"
    "grim"
    "slurp"
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
)

for pkg in "${packages[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        check_pass "$pkg installed"
    else
        check_fail "$pkg NOT installed"
    fi
done

################################################################################
# 2. CONFIGURATION FILES
################################################################################
section_header "2. Configuration Files"

configs=(
    "$HOME/.config/sway/config"
    "$HOME/.config/waybar/config"
    "$HOME/.config/waybar/style.css"
    "$HOME/.config/foot/foot.ini"
)

for cfg in "${configs[@]}"; do
    if [ -f "$cfg" ]; then
        check_pass "$(basename $cfg) exists"
    else
        check_warn "$(basename $cfg) missing (using defaults)"
    fi
done

################################################################################
# 3. SWAY CONFIGURATION VALIDITY
################################################################################
section_header "3. Sway Configuration Validation"

if command -v sway &>/dev/null; then
    if sway --validate 2>/dev/null; then
        check_pass "Sway config is valid"
    else
        check_fail "Sway config has errors"
        echo ""
        echo "Run: sway --validate"
        echo ""
    fi
else
    check_fail "Sway command not found"
fi

################################################################################
# 4. INTEL GPU DETECTION & DRIVERS
################################################################################
section_header "4. Intel GPU Detection"

# Check for Intel GPU
if lspci | grep -i vga | grep -qi intel; then
    check_pass "Intel GPU detected"
    
    # Get GPU model
    GPU_MODEL=$(lspci | grep -i vga | grep -i intel | cut -d: -f3)
    echo "      Model:$GPU_MODEL"
    
    # Check i915 module loaded
    if lsmod | grep -q i915; then
        check_pass "i915 kernel module loaded"
    else
        check_fail "i915 module not loaded"
    fi
    
    # Check DRI device
    if [ -e /dev/dri/card0 ]; then
        check_pass "/dev/dri/card0 exists"
    else
        check_fail "/dev/dri/card0 missing"
    fi
    
    # Check Mesa driver
    if command -v glxinfo &>/dev/null; then
        RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2)
        if echo "$RENDERER" | grep -qi "mesa\|intel"; then
            check_pass "Mesa driver active:$RENDERER"
        else
            check_warn "Unexpected renderer:$RENDERER"
        fi
    else
        check_warn "glxinfo not available (install mesa-utils)"
    fi
    
else
    check_warn "Intel GPU not detected (may be using different GPU)"
fi

################################################################################
# 5. KERNEL PARAMETERS
################################################################################
section_header "5. Intel i915 Kernel Parameters"

params=(
    "enable_rc6"
    "enable_fbc"
    "enable_psr"
    "fastboot"
)

for param in "${params[@]}"; do
    param_file="/sys/module/i915/parameters/$param"
    if [ -f "$param_file" ]; then
        value=$(cat "$param_file")
        if [ "$value" = "1" ] || [ "$value" = "Y" ]; then
            check_pass "$param = $value (enabled)"
        else
            check_warn "$param = $value (not optimized)"
        fi
    else
        check_warn "$param not available"
    fi
done

################################################################################
# 6. AUDIO SYSTEM
################################################################################
section_header "6. Audio System (PipeWire)"

# Check PipeWire running
if pgrep -x pipewire &>/dev/null; then
    check_pass "PipeWire is running"
else
    check_fail "PipeWire is NOT running"
fi

if pgrep -x pipewire-pulse &>/dev/null; then
    check_pass "PipeWire-Pulse is running"
else
    check_fail "PipeWire-Pulse is NOT running"
fi

if pgrep -x wireplumber &>/dev/null; then
    check_pass "WirePlumber is running"
else
    check_fail "WirePlumber is NOT running"
fi

# Check audio devices
if command -v wpctl &>/dev/null; then
    SINKS=$(wpctl status 2>/dev/null | grep -c "Sinks:" || echo "0")
    if [ "$SINKS" -gt 0 ]; then
        check_pass "Audio sinks detected"
    else
        check_warn "No audio sinks found"
    fi
fi

################################################################################
# 7. WAYLAND SESSION
################################################################################
section_header "7. Wayland Session"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    check_pass "Running Wayland session"
else
    check_warn "Not running Wayland (detected: $XDG_SESSION_TYPE)"
fi

if [ "$XDG_CURRENT_DESKTOP" = "sway" ]; then
    check_pass "Desktop environment: sway"
else
    check_warn "Desktop: $XDG_CURRENT_DESKTOP (expected 'sway')"
fi

# Check if Sway is running
if pgrep -x sway &>/dev/null; then
    check_pass "Sway compositor is running"
    
    # Check Sway version
    if command -v sway &>/dev/null; then
        SWAY_VER=$(sway --version 2>&1 | head -1)
        echo "      Version: $SWAY_VER"
    fi
else
    check_warn "Sway is not currently running (normal if checking from TTY)"
fi

################################################################################
# 8. FONTS
################################################################################
section_header "8. Fonts"

fonts=(
    "Font Awesome"
    "DejaVu Sans"
)

for font in "${fonts[@]}"; do
    if fc-list | grep -qi "$font"; then
        check_pass "$font installed"
    else
        check_warn "$font not found (may affect icons/display)"
    fi
done

################################################################################
# 9. SYSTEM RESOURCES
################################################################################
section_header "9. System Resources"

# RAM usage
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
USED_RAM=$(free -m | awk '/^Mem:/{print $3}')
FREE_RAM=$(free -m | awk '/^Mem:/{print $4}')

echo "  Total RAM: ${TOTAL_RAM}MB"
echo "  Used RAM:  ${USED_RAM}MB"
echo "  Free RAM:  ${FREE_RAM}MB"

if [ "$USED_RAM" -lt 500 ]; then
    check_pass "RAM usage is excellent (<500MB)"
elif [ "$USED_RAM" -lt 1000 ]; then
    check_pass "RAM usage is good (<1GB)"
else
    check_warn "RAM usage is high (${USED_RAM}MB)"
fi

# CPU info
CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
echo "  CPU: $CPU_MODEL"

# Load average
LOAD=$(uptime | awk -F'load average:' '{print $2}')
echo "  Load average:$LOAD"

################################################################################
# 10. GAMING SUPPORT
################################################################################
section_header "10. Gaming Support"

gaming_pkgs=(
    "gamemode"
    "mangohud"
    "gamescope"
)

for pkg in "${gaming_pkgs[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        check_pass "$pkg installed"
    else
        check_warn "$pkg not installed (optional)"
    fi
done

# Check Vulkan
if command -v vulkaninfo &>/dev/null; then
    if vulkaninfo --summary 2>/dev/null | grep -qi "deviceName.*Intel"; then
        check_pass "Vulkan working with Intel GPU"
    else
        check_warn "Vulkan may not be using Intel GPU"
    fi
else
    check_warn "vulkaninfo not available"
fi

################################################################################
# 11. SCREENSHOT DIRECTORY
################################################################################
section_header "11. Screenshot Directory"

if [ -d "$HOME/Pictures/Screenshots" ]; then
    check_pass "Screenshot directory exists"
else
    check_warn "Screenshot dir missing (will be created on first use)"
fi

################################################################################
# 12. AUTO-START CONFIGURATION
################################################################################
section_header "12. Auto-Start Configuration"

if [ -f "$HOME/.bash_profile" ]; then
    if grep -q "sway" "$HOME/.bash_profile"; then
        check_pass "Auto-start configured in .bash_profile"
    else
        check_warn "Sway not found in .bash_profile"
    fi
else
    check_warn ".bash_profile not found (manual start required)"
fi

################################################################################
# SUMMARY
################################################################################
section_header "VERIFICATION SUMMARY"

TOTAL=$((PASS + FAIL + WARN))

echo ""
echo -e "  ${GREEN}✓ Passed:${NC}  $PASS"
echo -e "  ${RED}✗ Failed:${NC}  $FAIL"
echo -e "  ${YELLOW}⚠ Warnings:${NC} $WARN"
echo -e "  Total checks: $TOTAL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ ALL CRITICAL CHECKS PASSED                                 ║${NC}"
    echo -e "${GREEN}║  Your Sway installation is ready to use!                      ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ SOME CHECKS FAILED                                          ║${NC}"
    echo -e "${RED}║  Review the errors above and fix before using Sway            ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
fi

if [ "$WARN" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Note: Warnings indicate optional features or minor issues.${NC}"
    echo -e "${YELLOW}The system should still be usable.${NC}"
fi

echo ""
echo -e "${BLUE}Troubleshooting Resources:${NC}"
echo "  • Check logs: journalctl --user -xe | grep sway"
echo "  • Validate config: sway --validate"
echo "  • Debug mode: sway --debug 2>&1 | tee ~/sway-debug.log"
echo "  • GitHub: https://github.com/BeanGreen247/sway-setup-script"
echo ""

################################################################################
# OPTIONAL: DETAILED SYSTEM INFO
################################################################################
read -p "Show detailed system information? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    section_header "DETAILED SYSTEM INFORMATION"
    
    echo ""
    echo "=== Neofetch ==="
    neofetch 2>/dev/null || echo "neofetch not installed"
    
    echo ""
    echo "=== GPU Info ==="
    lspci | grep -i vga
    
    echo ""
    echo "=== OpenGL Info ==="
    glxinfo | grep -E "OpenGL renderer|OpenGL version" 2>/dev/null || echo "glxinfo not available"
    
    echo ""
    echo "=== Vulkan Info ==="
    vulkaninfo --summary 2>/dev/null | head -20 || echo "vulkaninfo not available"
    
    echo ""
    echo "=== Audio Devices ==="
    wpctl status 2>/dev/null || echo "wpctl not available"
    
    echo ""
    echo "=== Sway IPC Outputs ==="
    swaymsg -t get_outputs 2>/dev/null || echo "Sway not running or swaymsg not available"
    
    echo ""
fi

echo -e "${GREEN}Verification complete!${NC}"
echo ""
