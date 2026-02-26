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
    # Remove ALL Microsoft/VSCode configurations (VSCode can be installed separately later)
    echo "Cleaning up any existing Microsoft/VSCode repository configuration..."
    
    # Remove all Microsoft GPG keyrings
    rm -f /usr/share/keyrings/packages.microsoft.gpg
    rm -f /usr/share/keyrings/microsoft.gpg
    rm -f /usr/share/keyrings/microsoft*.gpg
    
    # Remove ALL Microsoft-related source lists
    rm -f /etc/apt/sources.list.d/vscode.list*
    rm -f /etc/apt/sources.list.d/microsoft*.list*
    rm -f /etc/apt/sources.list.d/*vscode*
    rm -f /etc/apt/sources.list.d/*microsoft*
    
    # Clear apt cache
    rm -rf /var/lib/apt/lists/*
    mkdir -p /var/lib/apt/lists/partial
    
    echo "Installing development tools (Docker, Node.js, Python)..."
    apt update
    apt install -y docker.io docker-compose nodejs npm python3-pip python3-venv
    
    # Add user to docker group
    usermod -aG docker "$user"
    echo "✓ Development tools installed"
    echo "Note: VSCode can be installed later via: https://code.visualstudio.com/docs/setup/linux"
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
# OPTIONAL: Install Steam
# ============================================================================
read -p "Install Steam? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Ensure non-free repos are enabled (check if already configured)
    if ! grep -q "non-free" /etc/apt/sources.list; then
        echo "Adding non-free repositories for Steam..."
        sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    fi
    apt update
    apt install -y steam || echo "⚠ Steam installation failed - ensure non-free repos are enabled"
fi

# ============================================================================
# OPTIONAL: Install Lutris for game management
# ============================================================================
read -p "Install Lutris (game manager)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Install lutris and wine (wine includes both 32 and 64-bit support in Debian 13)
    apt install -y lutris wine wine32 wine64:i386 || apt install -y lutris wine
fi

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
# OPTIONAL: Install ZSH with Oh-My-Zsh
# ============================================================================
read -p "Install ZSH with Oh-My-Zsh? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y zsh
    su - "$user" -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    chsh -s /usr/bin/zsh "$user"
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
# CREATE USEFUL ALIASES
# ============================================================================
cat >> "/home/$user/.bashrc" << 'EOF'

# Sway-specific aliases
alias ll='ls -alh'
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias sway-reload='swaymsg reload'
alias sway-logs='journalctl -b -xe --user -u sway'
alias gpu-info='glxinfo | grep -i "renderer\|version"'
alias mem-usage='ps aux --sort=-%mem | head -20'
alias cpu-usage='ps aux --sort=-%cpu | head -20'
EOF

chown "$user:$user" "/home/$user/.bashrc"

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
