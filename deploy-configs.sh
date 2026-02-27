#!/bin/bash
################################################################################
# DEPLOY CONFIG FILES
# Copies config-files/ from this repo to the target user's ~/.config/
# Run as root: sudo bash deploy-configs.sh [username]
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_SRC="$SCRIPT_DIR/config-files"

# ─── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# ─── Root check ──────────────────────────────────────────────────────────────
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}ERROR: Must be run as root${NC}"
    echo "Usage: sudo bash deploy-configs.sh [username]"
    exit 1
fi

# ─── Detect / accept username ────────────────────────────────────────────────
if [ -n "$1" ]; then
    TARGET_USER="$1"
else
    TARGET_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
fi

if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    read -p "Enter the username to deploy configs for: " TARGET_USER
fi

if ! id "$TARGET_USER" &>/dev/null; then
    echo -e "${RED}ERROR: User '$TARGET_USER' does not exist${NC}"
    exit 1
fi

TARGET_HOME="/home/$TARGET_USER"
TARGET_CONFIG="$TARGET_HOME/.config"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo ""
echo -e "${GREEN}Deploying configs for user: $TARGET_USER${NC}"
echo "Source:      $CONFIG_SRC"
echo "Destination: $TARGET_CONFIG"
echo ""

# ─── Check source exists ─────────────────────────────────────────────────────
if [ ! -d "$CONFIG_SRC" ]; then
    echo -e "${RED}ERROR: config-files/ directory not found at $CONFIG_SRC${NC}"
    exit 1
fi

# ─── Helper: deploy one config directory ─────────────────────────────────────
deploy_dir() {
    local name="$1"          # e.g. "sway"
    local src="$CONFIG_SRC/$name"
    local dst="$TARGET_CONFIG/$name"

    if [ ! -d "$src" ]; then
        echo -e "${YELLOW}  SKIP $name (not in config-files/)${NC}"
        return
    fi

    # Backup existing config if it contains files
    if [ -d "$dst" ] && [ -n "$(ls -A "$dst" 2>/dev/null)" ]; then
        local backup="${dst}.backup.$TIMESTAMP"
        cp -r "$dst" "$backup"
        echo -e "  Backed up existing $name → ${backup##$TARGET_HOME/}"
    fi

    mkdir -p "$dst"

    # Copy all files except *.backup.*
    find "$src" -maxdepth 2 -type f ! -name "*.backup.*" | while read -r f; do
        rel="${f#$src/}"
        dst_file="$dst/$rel"
        mkdir -p "$(dirname "$dst_file")"
        cp "$f" "$dst_file"
    done

    echo -e "  ${GREEN}✓ $name${NC}"
}

# ─── Deploy each config directory ────────────────────────────────────────────
echo "Deploying config directories:"
deploy_dir sway
deploy_dir waybar
deploy_dir foot
deploy_dir swaync
deploy_dir gtk-3.0
deploy_dir rofi
deploy_dir gsimplecal

# ─── Deploy ~/.local/bin scripts ─────────────────────────────────────────────
echo "Deploying local bin scripts:"
LOCAL_BIN_SRC="$CONFIG_SRC/local-bin"
LOCAL_BIN_DST="$TARGET_HOME/.local/bin"
if [ -d "$LOCAL_BIN_SRC" ]; then
    mkdir -p "$LOCAL_BIN_DST"
    for f in "$LOCAL_BIN_SRC"/*; do
        cp "$f" "$LOCAL_BIN_DST/$(basename "$f")"
        chmod +x "$LOCAL_BIN_DST/$(basename "$f")"
    done
    chown -R "$TARGET_USER:$TARGET_USER" "$LOCAL_BIN_DST"
    echo -e "  ${GREEN}✓ local-bin${NC}"
fi

# ─── Patch hardcoded username in waybar config ───────────────────────────────
WAYBAR_CFG="$TARGET_CONFIG/waybar/config"
if [ -f "$WAYBAR_CFG" ]; then
    sed -i "s|/home/bean/|/home/$TARGET_USER/|g" "$WAYBAR_CFG"
    echo -e "  ${GREEN}✓ patched username in waybar config${NC}"
fi
# Patch username in sway config
SWAY_CFG="$TARGET_CONFIG/sway/config"
if [ -f "$SWAY_CFG" ]; then
    sed -i "s|/home/bean/|/home/$TARGET_USER/|g" "$SWAY_CFG"
    echo -e "  ${GREEN}✓ patched username in sway config${NC}"
fi
# Patch username in local-bin scripts too
for script in "$LOCAL_BIN_DST"/*; do
    [ -f "$script" ] && sed -i "s|/home/bean/|/home/$TARGET_USER/|g" "$script"
done

# ─── Deploy .desktop files ───────────────────────────────────────────────────
DESKTOP_SRC="$CONFIG_SRC/local-share-applications"
DESKTOP_DST="$TARGET_HOME/.local/share/applications"
if [ -d "$DESKTOP_SRC" ]; then
    mkdir -p "$DESKTOP_DST"
    for f in "$DESKTOP_SRC"/*.desktop; do
        cp "$f" "$DESKTOP_DST/$(basename "$f")"
        sed -i "s|/home/bean/|/home/$TARGET_USER/|g" "$DESKTOP_DST/$(basename "$f")"
    done
    chown -R "$TARGET_USER:$TARGET_USER" "$DESKTOP_DST"
    echo -e "  ${GREEN}✓ desktop entries${NC}"
fi

# ─── Fix permissions ─────────────────────────────────────────────────────────
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_CONFIG"
echo ""
echo -e "${GREEN}✓ All configs deployed and owned by $TARGET_USER${NC}"

# ─── Sway environment overlay ────────────────────────────────────────────────
# Ensure the environment file has Intel/Wayland variables set
ENV_FILE="$TARGET_CONFIG/sway/env"
if [ -f "$ENV_FILE" ]; then
    # Make sure the critical Intel VA-API lines are present
    grep -qxF 'export LIBVA_DRIVER_NAME=i965'  "$ENV_FILE" || \
        echo 'export LIBVA_DRIVER_NAME=i965'  >> "$ENV_FILE"
    grep -qxF 'export VDPAU_DRIVER=va_gl'      "$ENV_FILE" || \
        echo 'export VDPAU_DRIVER=va_gl'       >> "$ENV_FILE"
    grep -qxF 'export MOZ_ENABLE_WAYLAND=1'    "$ENV_FILE" || \
        echo 'export MOZ_ENABLE_WAYLAND=1'     >> "$ENV_FILE"
    grep -qxF 'export XDG_CURRENT_DESKTOP=sway' "$ENV_FILE" || \
        echo 'export XDG_CURRENT_DESKTOP=sway' >> "$ENV_FILE"
    echo -e "  ${GREEN}✓ sway/env verified${NC}"
fi

# ─── Sway auto-start on TTY1 ─────────────────────────────────────────────────
BASH_PROFILE="$TARGET_HOME/.bash_profile"
if ! grep -q 'exec sway' "$BASH_PROFILE" 2>/dev/null; then
    cat >> "$BASH_PROFILE" << 'EOF'

# Auto-start Sway on TTY1
if [ -z "$DISPLAY" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
    exec sway
fi
EOF
    chown "$TARGET_USER:$TARGET_USER" "$BASH_PROFILE"
    echo -e "  ${GREEN}✓ .bash_profile updated for sway auto-start${NC}"
fi

echo ""
echo -e "${GREEN}Done. Configs are live — reboot or reload sway (Super+Shift+C).${NC}"
echo ""
