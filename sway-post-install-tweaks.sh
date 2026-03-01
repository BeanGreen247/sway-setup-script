#!/bin/bash
################################################################################
# Sway Post-Install Tweaks & Optimizations
# Run this AFTER sway-minimal-install.sh for additional enhancements
################################################################################

set -e

if [ "$(id -u)" != "0" ]; then
    echo "Run as root: sudo bash $0"
    exit 1
fi

user="${SUDO_USER:-$(logname 2>/dev/null)}"
if [ -z "$user" ]; then
    read -p "Enter username: " user
fi

echo "════════════════════════════════════════════════════════"
echo "  Sway Post-Install Tweaks for $user"
echo "════════════════════════════════════════════════════════"

# ============================================================================
# OPTIONAL: Install additional useful applications
# ============================================================================
read -p "Install additional apps? (Firefox, VSCode, GIMP, VLC) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y \
        chromium \
        vlc \
        gimp \
        inkscape \
        libreoffice \
        thunderbird \
        keepassxc \
        transmission-gtk \
        mpv \
        imv \
        zathura \
        gnome-calculator
fi

# ============================================================================
# OPTIONAL: Install development tools
# ============================================================================
read -p "Install development tools? (Docker, Node.js, Python) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing development tools (Docker, Node.js, Python)..."
    apt update
    apt install -y docker.io docker-compose nodejs npm python3-pip python3-venv

    # Add user to docker group
    usermod -aG docker "$user"
    echo "✓ Development tools installed"
fi

# ============================================================================
# PERFORMANCE: CPU Governor Optimization (Modern Approach)
# ============================================================================
read -p "Set CPU governor to 'schedutil' for balance? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Modern approach: Use systemd service to set governor at boot
    cat > /etc/systemd/system/cpu-governor.service << 'GOVEOF'
[Unit]
Description=Set CPU frequency scaling governor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo schedutil > $cpu 2>/dev/null || true; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
GOVEOF
    
    systemctl daemon-reload
    systemctl enable cpu-governor.service
    systemctl start cpu-governor.service
    echo "✓ CPU governor set to 'schedutil' and enabled at boot"
fi

# ============================================================================
# PERFORMANCE: Swappiness Tuning (with 40GB RAM, reduce swap usage)
# ============================================================================
read -p "Reduce swappiness to 10? (recommended with 40GB RAM) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
    sysctl -p /etc/sysctl.d/99-swappiness.conf
fi

# ============================================================================
# PERFORMANCE: zram Setup (compressed RAM swap)
# ============================================================================
echo -e "\e[1;31m[Setting up zram...]\e[1;0m\n"

# Install systemd zram generator if not present
if ! dpkg -l systemd-zram-generator &>/dev/null; then
    apt install -y systemd-zram-generator
fi

# Detect total RAM in MB
ram_mb=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)

# Calculate zram size based on RAM amount
if [ "$ram_mb" -lt 8192 ]; then
    # < 8 GB: 2x RAM
    zram_mb=$((ram_mb * 2))
    zram_rule="< 8 GB → 2×"
elif [ "$ram_mb" -lt 16384 ]; then
    # 8–15 GB: 1x RAM
    zram_mb=$ram_mb
    zram_rule="8–15 GB → 1×"
elif [ "$ram_mb" -lt 32768 ]; then
    # 16–31 GB: 0.75x RAM
    zram_mb=$((ram_mb * 3 / 4))
    zram_rule="16–31 GB → 0.75×"
elif [ "$ram_mb" -lt 65536 ]; then
    # 32–63 GB: 0.5x RAM
    zram_mb=$((ram_mb / 2))
    zram_rule="32–63 GB → 0.5×"
elif [ "$ram_mb" -lt 262144 ]; then
    # 64–255 GB: 0.25x RAM
    zram_mb=$((ram_mb / 4))
    zram_rule="64–255 GB → 0.25×"
else
    # >= 256 GB: 0.125x RAM
    zram_mb=$((ram_mb / 8))
    zram_rule=">= 256 GB → 0.125×"
fi

# Apply 4 GB minimum floor
min_zram_mb=4096
if [ "$zram_mb" -lt "$min_zram_mb" ]; then
    zram_mb=$min_zram_mb
    zram_rule="${zram_rule} (floored to 4 GB minimum)"
fi

echo "  Detected RAM : ${ram_mb} MB"
echo "  Rule applied : ${zram_rule}"
echo "  zram size    : ${zram_mb} MB"

# Write zram-generator config
tee /usr/lib/systemd/zram-generator.conf > /dev/null << EOF
# This config file enables a /dev/zram0 device.
# Size is calculated from host RAM (minimum 4 GB):
#   < 8 GB    → 2x RAM  (min 4 GB)
#   8–15 GB   → 1x RAM
#   16–31 GB  → 0.75x RAM
#   32–63 GB  → 0.5x RAM
#   64–255 GB → 0.25x RAM
#   >= 256 GB → 0.125x RAM
# To disable, uninstall systemd-zram-generator or create an empty
# /etc/systemd/zram-generator.conf file.
[zram0]
zram-size = min(ram, ${zram_mb})
EOF

systemctl daemon-reload
systemctl start dev-zram0.swap
zramctl

echo -e "Setting up zram...\e[1;32m[DONE]\e[1;0m\n"

# ============================================================================
# OPTIONAL: Enable Night Light (Wayland gamma control)
# ============================================================================
read -p "Install wlsunset (auto night light)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y wlsunset
    # Add to sway config
    if ! grep -q "wlsunset" "/home/$user/.config/sway/config"; then
        echo "" >> "/home/$user/.config/sway/config"
        echo "# Night light (adjust latitude/longitude)" >> "/home/$user/.config/sway/config"
        echo "exec wlsunset -l 40.7 -L -74.0" >> "/home/$user/.config/sway/config"
    fi
fi

# ============================================================================
# OPTIONAL: Install clipboard manager
# ============================================================================
read -p "Install clipboard manager (cliphist)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # cliphist might not be in repos - try to install from backports or skip
    if apt install -y cliphist 2>/dev/null; then
        echo "✓ cliphist installed"
        if ! grep -q "wl-paste.*cliphist" "/home/$user/.config/sway/config"; then
            echo "" >> "/home/$user/.config/sway/config"
            echo "# Clipboard manager" >> "/home/$user/.config/sway/config"
            echo "exec wl-paste --watch cliphist store" >> "/home/$user/.config/sway/config"
            echo "bindsym \$mod+v exec cliphist list | wofi -dmenu | cliphist decode | wl-copy" >> "/home/$user/.config/sway/config"
        fi
    else
        echo "⚠ cliphist not available in repositories - using wl-clipboard instead"
        echo "Tip: Use 'wl-paste' and 'wl-copy' commands for clipboard operations"
    fi
fi

# ============================================================================
# THEME: GTK Theme Installation
# ============================================================================
read -p "Install Arc/Dracula dark themes? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y arc-theme papirus-icon-theme
    
    mkdir -p "/home/$user/.config/gtk-3.0"
    cat > "/home/$user/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=DejaVu Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF
    chown -R "$user:$user" "/home/$user/.config/gtk-3.0"
fi

# ============================================================================
# THEME: Midnight-Blue GTK Theme
# Custom maintained theme: https://github.com/BeanGreen247/catppuccin-midnight-gtk
# Patched from Catppuccin Mocha Blue; maps purple-grey → midnight navy/blue
# to match sway/waybar/rofi palette in this setup.
# ============================================================================
read -p "Install Midnight-Blue GTK theme? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y curl tar

    THEME_URL="https://github.com/BeanGreen247/catppuccin-midnight-gtk/releases/latest/download/Midnight-Blue.tar.gz"
    THEME_DEST="/usr/share/themes/Midnight-Blue"
    TMP_DIR="$(mktemp -d)"

    echo "  Downloading Midnight-Blue from github.com/BeanGreen247/catppuccin-midnight-gtk..."
    if curl -fsSL "$THEME_URL" -o "$TMP_DIR/Midnight-Blue.tar.gz"; then
        rm -rf "$THEME_DEST"
        tar -xzf "$TMP_DIR/Midnight-Blue.tar.gz" -C /usr/share/themes/

        # Update gtk settings to use the new theme
        mkdir -p "/home/$user/.config/gtk-3.0"
        sed -i 's/^gtk-theme-name=.*/gtk-theme-name=Midnight-Blue/' \
            "/home/$user/.config/gtk-3.0/settings.ini" 2>/dev/null || true

        chown -R "$user:$user" "/home/$user/.config/gtk-3.0"
        rm -rf "$TMP_DIR"
        echo "✓ Midnight-Blue theme installed → $THEME_DEST"
        echo "  Select it in lxappearance under Widget > Midnight-Blue"
    else
        echo "⚠ Download failed — push a release to github.com/BeanGreen247/catppuccin-midnight-gtk first"
        echo "  Build manually: cd ~/catppuccin-midnight-gtk && sudo bash build.sh --install"
        rm -rf "$TMP_DIR"
    fi
fi

# ============================================================================
# SECURITY: Enable firewall
# ============================================================================
read -p "Enable UFW firewall? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y ufw
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    systemctl enable ufw
fi

# ============================================================================
# INTEL GPU: Monitor temperature and clocks
# ============================================================================
read -p "Create Intel GPU monitoring script? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > "/usr/local/bin/gpu-stats" << 'EOF'
#!/bin/bash
# Intel GPU stats monitor
echo "=== Intel GPU Statistics ==="
intel_gpu_top -o - | head -20 &
PID=$!
sleep 3
kill $PID
echo ""
echo "=== GPU Frequency ==="
cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo "N/A"
echo ""
echo "=== Sensors ==="
sensors | grep -i "core\|package"
EOF
    chmod +x /usr/local/bin/gpu-stats
    echo "✓ Run 'gpu-stats' to monitor Intel GPU"
fi

# ============================================================================
# SET PERMISSIONS
# ============================================================================
chown -R "$user:$user" "/home/$user/.config"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✓ Post-install tweaks complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Reboot recommended: sudo systemctl reboot"
echo ""
