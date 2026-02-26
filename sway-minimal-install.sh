#!/bin/bash
################################################################################
# Optimized Minimal Sway Install Script for Debian
# Target Hardware: Intel i5-6500T (HD 530 iGPU), 40GB RAM, 1TB HDD
# Goal: <200MB idle RAM, tear-free Wayland, no wallpaper
# From minimal Debian netinstall - run as root
################################################################################

set -e

# ============================================================================
# USER DETECTION & VALIDATION
# ============================================================================
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run as root"
    echo "Usage: sudo bash $0"
    exit 1
fi

# Auto-detect user or prompt
user=$(logname 2>/dev/null || echo "$SUDO_USER")
if [ -z "$user" ] || [ "$user" = "root" ]; then
    read -p "Enter username to configure (will be created if missing): " user
fi

# Create user if doesn't exist
if ! id "$user" &>/dev/null; then
    echo "Creating user: $user"
    adduser --gecos "" "$user"
fi

echo "=============================================================================="
echo "Setting up minimal Sway environment for user: $user"
echo "Target: Intel HD 530 iGPU with <200MB idle RAM"
echo "=============================================================================="

# ============================================================================
# SYSTEM UPDATE & i386 ARCHITECTURE (for Steam/Wine/Gaming)
# ============================================================================
echo "[1/8] Updating system and adding i386 architecture..."
dpkg --add-architecture i386
apt update -qq
apt upgrade -qq -y

# ============================================================================
# CORE PACKAGES INSTALLATION
# ============================================================================
echo "[2/8] Installing core Sway packages..."

# Core Wayland/Sway stack
apt install -y \
    sway swaybg swayidle swaylock \
    xdg-desktop-portal-wlr xwayland \
    waybar foot wofi wl-clipboard grim slurp \
    sway-notification-center libnotify-bin \
    \
    pipewire pipewire-pulse pipewire-alsa wireplumber pipewire-audio-client-libraries \
    \
    mesa-utils mesa-vulkan-drivers mesa-va-drivers \
    intel-media-va-driver intel-gpu-tools intel-microcode \
    vulkan-tools libvulkan-dev libgl1-mesa-dri libglu1-mesa \
    libgl1:i386 libgl1-mesa-dri:i386 libglu1-mesa:i386 \
    \
    brightnessctl pavucontrol pulseaudio-utils pamixer lxappearance \
    pcmanfm xarchiver p7zip-full unzip dmenu curl wget \
    firefox-esr \
    \
    fonts-font-awesome fonts-dejavu-core ttf-mscorefonts-installer \
    \
    vim git curl wget tree htop btop fastfetch \
    lm-sensors fancontrol \
    \
    mate-polkit polkitd \
    \
    ca-certificates build-essential cmake gcc g++

echo "[2.5] Installing brave browser"
bash -c "curl -fsS https://dl.brave.com/install.sh | sh"

# Steam support libraries (multilib)
echo "[3/8] Installing Steam/Gaming support libraries..."
apt install -y \
    libc6:i386 libegl1:i386 libgbm1:i386 \
    steam-libs-amd64:amd64 steam-libs-i386:i386 \
    gamemode mangohud goverlay vkbasalt || true

# Optional: Install Steam (comment out if not needed)
# apt install -y steam

# ============================================================================
# CLEANUP APT CACHE
# ============================================================================
echo "[4/8] Cleaning package cache..."
apt autoremove -y --purge
apt autoclean
apt clean

# ============================================================================
# INTEL HD 530 GPU OPTIMIZATIONS
# ============================================================================
echo "[5/8] Configuring Intel HD 530 iGPU optimizations..."

# Intel i915 kernel module optimizations
cat > /etc/modprobe.d/i915.conf << 'EOF'
# Intel HD 530 optimizations
options i915 enable_rc6=1 enable_fbc=1 enable_psr=1 disable_power_well=0
options i915 fastboot=1 enable_guc=2 enable_dc=2
EOF

# Update initramfs
update-initramfs -u -k all

# ============================================================================
# USER CONFIGURATION DIRECTORIES
# ============================================================================
echo "[6/8] Creating user configuration directories..."

mkdir -p "/home/$user/.config"/{sway,waybar,foot,swaync}
mkdir -p "/home/$user/.fonts"
mkdir -p "/home/$user/Pictures/Screenshots"

# ============================================================================
# DOWNLOAD SWAY CONFIGURATIONS FROM GITHUB
# ============================================================================
echo "[7/8] Downloading Sway configurations from GitHub..."

# Sway configs
wget -q -O "/home/$user/.config/sway/config" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/config || \
    echo "Warning: Could not download sway config, will create minimal one"

wget -q -O "/home/$user/.config/sway/general_keybinds" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/general_keybinds || true

wget -q -O "/home/$user/.config/sway/desktop_keybinds" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/desktop_keybinds || true

wget -q -O "/home/$user/.config/sway/laptop_keybinds" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/laptop_keybinds || true

# Waybar configs
wget -q -O "/home/$user/.config/waybar/config" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/waybar/config || \
    echo "Warning: Could not download waybar config"

wget -q -O "/home/$user/.config/waybar/style.css" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/waybar/style.css || \
    echo "Warning: Could not download waybar style"

# Foot terminal
wget -q -O "/home/$user/.config/foot/foot.ini" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/foot/foot.ini || \
    echo "Warning: Could not download foot config"

# Sway Notification Center
wget -q -O "/home/$user/.config/swaync/config.json" \
    https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/swaync/config.json || \
    echo "Warning: Could not download swaync config"

# ============================================================================
# FALLBACK: CREATE MINIMAL SWAY CONFIG IF DOWNLOAD FAILED
# ============================================================================
if [ ! -f "/home/$user/.config/sway/config" ]; then
    echo "Creating fallback minimal Sway config..."
    cat > "/home/$user/.config/sway/config" << 'SWAYEOF'
# Minimal Sway Config - Intel HD 530 Optimized
# No wallpaper = CPU/GPU savings

set $mod Mod4
set $term foot
set $menu wofi --show drun

# Autostart essentials
exec swaync
exec mate-polkit

# Output configuration (no wallpaper for performance)
output * bg #000000 solid_color

# Idle management
exec swayidle -w \
    timeout 300 'swaylock -f -c 000000' \
    timeout 600 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -f -c 000000'

# Input configuration
input type:keyboard {
    xkb_layout us
    xkb_options ctrl:nocaps
    repeat_delay 300
    repeat_rate 30
}

input type:touchpad {
    tap enabled
    natural_scroll enabled
    dwt enabled
}

# Core keybinds
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# Movement
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Move windows
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

# Move to workspace
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

# Layout
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# Scratchpad
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show

# Screenshots
bindsym Print exec grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot copied to clipboard"
bindsym $mod+Shift+s exec systemctl suspend

# Media keys
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# Notification center
bindsym $mod+n exec swaync-client -t -sw

# Resize mode
mode "resize" {
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    bindsym h resize shrink width 10px
    bindsym j resize grow height 10px
    bindsym k resize shrink height 10px
    bindsym l resize grow width 10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Status bar
bar {
    swaybar_command waybar
}

# Performance optimizations
focus_follows_mouse no
mouse_warping none

# Disable xwayland if not needed (saves resources)
# xwayland disable

# Set max render time (helps with Intel iGPU)
max_render_time 3
SWAYEOF
fi

# ============================================================================
# FALLBACK WAYBAR CONFIG
# ============================================================================
if [ ! -f "/home/$user/.config/waybar/config" ]; then
    cat > "/home/$user/.config/waybar/config" << 'WAYBAREOF'
{
  "reload_style_on_change": true,
  "layer": "top",
  "position": "top",
  "spacing": 4,
  "height": 36,
  "margin-top": 8,
  "margin-right": 12,
  "margin-left": 12,

  "modules-left": ["sway/workspaces", "sway/mode"],
  "modules-center": ["clock#day", "clock#date", "clock#time"],
  "modules-right": [
    "cpu",
    "memory",
    "disk",
    "temperature",
    "pulseaudio",
    "network",
    "battery",
    "tray"
  ],

  "sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{name}"
  },

  "sway/mode": {
    "format": "  {}"
  },

  "clock#day": {
    "format": "{:%A}",
    "tooltip": false
  },

  "clock#date": {
    "format": "{:%d %b %Y}",
    "tooltip": false
  },

  "clock#time": {
    "interval": 1,
    "format": "{:%H:%M:%S}",
    "tooltip-format": "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>"
  },

  "cpu": {
    "interval": 2,
    "format": "\uf2db {usage}%",
    "tooltip-format": "CPU: {usage}%  load: {load}"
  },

  "memory": {
    "interval": 2,
    "format": "\uf538 {percentage}%",
    "tooltip-format": "{used:0.1f} GiB / {total:0.1f} GiB used"
  },

  "disk": {
    "interval": 30,
    "format": "\uf1c0 {percentage_used}%",
    "path": "/",
    "tooltip-format": "Used:  {used}\nFree:  {free}\nTotal: {total}"
  },

  "temperature": {
    "critical-threshold": 80,
    "interval": 5,
    "format": "\uf2c9 {temperatureC}\u00b0C",
    "format-critical": "\uf2c9 {temperatureC}\u00b0C",
    "tooltip": false
  },

  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": "\uf6a9 muted",
    "on-click": "pavucontrol",
    "on-click-right": "pamixer -t",
    "tooltip-format": "{desc}\nVolume: {volume}%",
    "scroll-step": 5,
    "format-icons": {
      "default": ["\uf026", "\uf027", "\uf028"]
    }
  },

  "network": {
    "format-wifi": "\uf1eb {signalStrength}%",
    "format-ethernet": "\uf796",
    "format-disconnected": "\uf071 off",
    "format-linked": "\uf796",
    "tooltip-format-wifi": "{essid}\nSignal: {signalStrength}%\n\u2193 {bandwidthDownBytes}  \u2191 {bandwidthUpBytes}",
    "tooltip-format-ethernet": "{ifname}\n\u2193 {bandwidthDownBytes}  \u2191 {bandwidthUpBytes}",
    "tooltip-format-disconnected": "No connection",
    "interval": 3
  },

  "battery": {
    "format": "{icon} {capacity}%",
    "format-charging": "\uf0e7 {capacity}%",
    "format-plugged": "\uf1e6 {capacity}%",
    "format-full": "\uf240 full",
    "format-icons": ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"],
    "tooltip-format": "{timeTo}  \u00b7  {power:0.1f}W",
    "interval": 5,
    "states": {
      "warning": 30,
      "critical": 15
    }
  },

  "tray": {
    "icon-size": 16,
    "spacing": 8
  }
}
WAYBAREOF
fi

# Fallback Waybar style
if [ ! -f "/home/$user/.config/waybar/style.css" ]; then
    cat > "/home/$user/.config/waybar/style.css" << 'WAYBARCSS'
/* ════════════════════════════════════════════════════════════
 *  MIDNIGHT GLASS  ·  Modern Waybar Theme
 *  Floating pill bar · Deep glass layers · Accent highlights
 * ════════════════════════════════════════════════════════════ */

/* ── BASE ─────────────────────────────────────────────────── */
* {
  border: none;
  border-radius: 0;
  min-height: 0;
  font-family: "JetBrains Mono", monospace;
  font-size: 12.5px;
  font-weight: 400;
  color: #dce8f5;
}

/* ── TOP-LEVEL WINDOW ─────────────────────────────────────── */
window#waybar {
  background: transparent;
}

/* ── MODULE ZONES ─────────────────────────────────────────── */
.modules-left {
  background: rgba(12, 18, 34, 0.82);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 14px;
  margin-left: 0px;
  padding: 0 4px;
}

.modules-center {
  background: rgba(12, 18, 34, 0.82);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 14px;
  padding: 0 6px;
}

.modules-right {
  background: rgba(12, 18, 34, 0.82);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 14px;
  margin-right: 0px;
  padding: 0 4px;
}

/* ── WORKSPACES ───────────────────────────────────────────── */
#workspaces {
  padding: 0 4px;
}

#workspaces button {
  color: rgba(220, 232, 245, 0.40);
  background: transparent;
  padding: 0 7px;
  margin: 4px 2px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 12px;
  min-width: 22px;
  transition: all 120ms ease;
}

#workspaces button:hover {
  color: rgba(220, 232, 245, 0.75);
  background: rgba(255, 255, 255, 0.07);
}

#workspaces button.focused {
  color: #0c1222;
  background: #58a6ff;
  border-radius: 8px;
  margin: 5px 3px;
  padding: 0 8px;
  font-weight: 800;
}

#workspaces button.urgent {
  color: #fff;
  background: rgba(255, 80, 80, 0.75);
  border-radius: 8px;
}

/* ── SWAY MODE ────────────────────────────────────────────── */
#mode {
  background: rgba(88, 166, 255, 0.20);
  color: #58a6ff;
  border: 1px solid rgba(88, 166, 255, 0.35);
  border-radius: 10px;
  font-weight: 700;
  padding: 0 10px;
  margin: 4px 4px;
}

/* ── CLOCK ────────────────────────────────────────────────── */
#clock.day {
  color: rgba(220, 232, 245, 0.50);
  font-weight: 400;
  font-size: 12px;
  padding-right: 2px;
  padding-left: 6px;
}

#clock.date {
  color: rgba(220, 232, 245, 0.75);
  font-weight: 500;
  font-size: 12.5px;
  border-left: 1px solid rgba(255,255,255,0.08);
  border-right: 1px solid rgba(255,255,255,0.08);
  padding: 0 10px;
  margin: 4px 2px;
}

#clock.time {
  color: #dce8f5;
  font-weight: 700;
  font-size: 13.5px;
  letter-spacing: 1px;
  padding-left: 2px;
  padding-right: 6px;
}

/* ── CPU ──────────────────────────────────────────────────── */
#cpu {
  color: #58a6ff;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

#cpu.high { color: #ff9944; }

/* ── MEMORY ───────────────────────────────────────────────── */
#memory {
  color: #79c0ff;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

/* ── DISK ─────────────────────────────────────────────────── */
#disk {
  color: #a5d6ff;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

/* ── TEMPERATURE ──────────────────────────────────────────── */
#temperature {
  color: #56d364;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

#temperature.critical {
  color: #ff5555;
  animation: blink 1s linear infinite;
}

@keyframes blink {
  0%   { opacity: 1; }
  50%  { opacity: 0.4; }
  100% { opacity: 1; }
}

/* ── PULSEAUDIO ───────────────────────────────────────────── */
#pulseaudio {
  color: #c792ea;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

#pulseaudio.muted { color: rgba(220, 232, 245, 0.30); }

/* ── NETWORK ──────────────────────────────────────────────── */
#network {
  color: #56d364;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

#network.disconnected { color: rgba(255, 85, 85, 0.75); }
#network.wifi { color: #56d364; }
#network.ethernet { color: #79c0ff; }

/* ── BATTERY ──────────────────────────────────────────────── */
#battery {
  color: #3fb950;
  font-family: "Font Awesome 6 Free", "JetBrains Mono", monospace;
  font-weight: 900;
  padding: 0 6px;
}

#battery.charging { color: #58a6ff; }
#battery.plugged { color: #79c0ff; }
#battery.warning:not(.charging) { color: #e3b341; }

#battery.critical:not(.charging) {
  color: #ff5555;
  animation: blink 1s linear infinite;
}

/* ── TRAY ─────────────────────────────────────────────────── */
#tray { padding: 0 6px; }
#tray > .passive { -gtk-icon-effect: dim; }
#tray > .needs-attention {
  -gtk-icon-effect: highlight;
  background-color: rgba(255, 85, 85, 0.15);
  border-radius: 6px;
}

/* ── TOOLTIPS ─────────────────────────────────────────────── */
tooltip {
  background: rgba(10, 14, 26, 0.96);
  border: 1px solid rgba(88, 166, 255, 0.20);
  border-radius: 10px;
  padding: 4px 2px;
}

tooltip label {
  color: #dce8f5;
  font-size: 12px;
  padding: 2px 6px;
}
WAYBARCSS
fi

# ============================================================================
# FALLBACK FOOT CONFIG
# ============================================================================
if [ ! -f "/home/$user/.config/foot/foot.ini" ]; then
    cat > "/home/$user/.config/foot/foot.ini" << 'FOOTEOF'
[main]
font=DejaVu Sans Mono:size=11
dpi-aware=yes

[cursor]
style=beam
blink=yes

[colors]
alpha=0.95
background=000000
foreground=ffffff
FOOTEOF
fi

# ============================================================================
# FALLBACK SWAYNC CONFIG
# ============================================================================
if [ ! -f "/home/$user/.config/swaync/config.json" ]; then
    cat > "/home/$user/.config/swaync/config.json" << 'SWAYNCEOF'
{
  "positionX": "right",
  "positionY": "top",
  "layer": "overlay",
  "control-center-layer": "overlay",
  "layer-shell": true,
  "cssPriority": "application",
  "control-center-margin-top": 0,
  "control-center-margin-bottom": 0,
  "control-center-margin-right": 0,
  "control-center-margin-left": 0,
  "notification-2fa-action": true,
  "notification-inline-replies": false,
  "notification-icon-size": 64,
  "notification-body-image-height": 100,
  "notification-body-image-width": 200,
  "timeout": 10,
  "timeout-low": 5,
  "timeout-critical": 0,
  "fit-to-screen": true,
  "control-center-width": 500,
  "control-center-height": 600,
  "notification-window-width": 500,
  "keyboard-shortcuts": true,
  "image-visibility": "when-available",
  "transition-time": 200,
  "hide-on-clear": false,
  "hide-on-action": true,
  "script-fail-notify": true
}
SWAYNCEOF
fi

# ============================================================================
# FONT AWESOME INSTALLATION
# ============================================================================
echo "[8/8] Installing Font Awesome..."

cd "/home/$user"
FA_VERSION="6.7.2"  # Update to latest version as needed
FA_URL="https://use.fontawesome.com/releases/v${FA_VERSION}/fontawesome-free-${FA_VERSION}-desktop.zip"

# Try to download latest Font Awesome
if wget -q "$FA_URL" -O fontawesome.zip 2>/dev/null; then
    unzip -q fontawesome.zip
    cp -r fontawesome-free-${FA_VERSION}-desktop/otfs/*.otf "/home/$user/.fonts/" 2>/dev/null || true
    cp -r fontawesome-free-${FA_VERSION}-desktop/otfs/*.otf /usr/local/share/fonts/ 2>/dev/null || true
    rm -rf fontawesome* fontawesome.zip
else
    echo "Note: Font Awesome download failed, using system package version"
fi

# ============================================================================
# AUTO-START SWAY ON LOGIN
# ============================================================================
cat > "/home/$user/.bash_profile" << 'EOF'
# Auto-start Sway on login (TTY1 only)
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec sway
fi
EOF

# ============================================================================
# SET PROPER PERMISSIONS
# ============================================================================
chown -R "$user:$user" "/home/$user/.config"
chown -R "$user:$user" "/home/$user/.fonts"
chown "$user:$user" "/home/$user/.bash_profile"
chown -R "$user:$user" "/home/$user/Pictures"

# ============================================================================
# REBUILD FONT CACHE
# ============================================================================
echo "Rebuilding font cache..."
su - "$user" -c "fc-cache -f -v" &>/dev/null

# ============================================================================
# CREATE ENVIRONMENT FILE FOR SWAY
# ============================================================================
cat > "/home/$user/.config/sway/env" << 'EOF'
# Environment variables for Sway
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export LIBVA_DRIVER_NAME=i965
export VDPAU_DRIVER=va_gl
EOF

chown "$user:$user" "/home/$user/.config/sway/env"

# ============================================================================
# FINAL OPTIMIZATIONS
# ============================================================================
echo "Applying final system optimizations..."

# Enable gamemode for better performance when gaming
systemctl --user -M "$user@" enable gamemoded 2>/dev/null || true

# Detect sensors
sensors-detect --auto &>/dev/null || true

# ============================================================================
# COMPLETION MESSAGE
# ============================================================================
clear
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║                   ✓ SWAY INSTALLATION COMPLETE                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Target Specs:                                                            ║
║    • ~150-200MB idle RAM usage                                            ║
║    • Intel HD 530 iGPU optimized                                          ║
║    • Tear-free Wayland compositing                                        ║
║    • PipeWire audio (low CPU overhead)                                    ║
║    • No wallpaper for CPU/GPU savings                                     ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Essential Keybinds:                                                      ║
║    Super + Enter          → Open terminal (Foot)                          ║
║    Super + D              → Application launcher (Wofi)                   ║
║    Super + 1-9            → Switch workspaces                             ║
║    Super + Shift + 1-9    → Move window to workspace                      ║
║    Super + Shift + Q      → Close window                                  ║
║    Super + Shift + S      → Screenshot (selection)                        ║
║    Super + N              → Toggle notification center                    ║
║    Super + Shift + E      → Exit Sway                                     ║
║    Super + R              → Resize mode                                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Next Steps:                                                              ║
║    1. Reboot your system: sudo systemctl reboot                           ║
║    2. Log in as the configured user                                       ║
║    3. Sway will auto-start on TTY1                                        ║
║    4. Run 'sensors' to check CPU temperature monitoring                   ║
║    5. Run 'neofetch' or 'htop' to check resource usage                    ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Installed Applications:                                                  ║
║    • Firefox ESR (web browser)                                            ║
║    • PCManFM (file manager)                                               ║
║    • Pavucontrol (audio mixer)                                            ║
║    • MangoHud/Goverlay (gaming overlay)                                   ║
║    • GameMode (gaming performance)                                        ║
║    • Foot (terminal)                                                      ║
║    • Waybar (status bar)                                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Configuration Files:                                                     ║
║    ~/.config/sway/config                                                  ║
║    ~/.config/waybar/{config,style.css}                                    ║
║    ~/.config/foot/foot.ini                                                ║
║    ~/.config/swaync/config.json                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo "Configured for user: $user"
echo ""
echo "To start Sway NOW (without reboot): su - $user -c 'sway'"
echo "Or reboot: systemctl reboot"
echo ""
