# Sway Minimal Setup - Quick Reference Card
## Hardware: Intel i5-6500T (HD 530 iGPU) | 40GB RAM | 1TB HDD

---

## Installation Order

```bash
# 1. Setup Debian repositories (as root)
sudo bash sources_list_setup.sh

# 2. Main Sway installation (as root)
sudo bash sway-minimal-install.sh

# 3. (Optional) Post-install tweaks (as root)
sudo bash sway-post-install-tweaks.sh

# 4. Reboot
sudo systemctl reboot
```

---

## Essential Keybinds

| **Shortcut**              | **Action**                         |
|---------------------------|------------------------------------|
| `Super + Enter`           | Open terminal (Foot)               |
| `Super + D`               | Application launcher (Wofi)        |
| `Super + Shift + Q`       | Close window                       |
| `Super + Shift + E`       | Exit Sway                          |
| `Super + Shift + C`       | Reload Sway config                 |
| `Super + 1-9`             | Switch to workspace 1-9            |
| `Super + Shift + 1-9`     | Move window to workspace           |
| `Super + Shift + S`       | Screenshot (area selection)        |
| `Print`                   | Screenshot (full screen)           |
| `Super + N`               | Toggle notification center         |
| `Super + R`               | Resize mode                        |
| `Super + F`               | Fullscreen toggle                  |
| `Super + Shift + Space`   | Toggle floating                    |
| `Super + Arrow Keys`      | Focus window (direction)           |
| `Super + H/J/K/L`         | Focus window (Vim-style)           |

---

## Media Keys

| **Key**                     | **Action**                      |
|-----------------------------|---------------------------------|
| `XF86AudioRaiseVolume`      | Volume up 5%                    |
| `XF86AudioLowerVolume`      | Volume down 5%                  |
| `XF86AudioMute`             | Mute/unmute                     |
| `XF86MonBrightnessUp`       | Brightness up 5%                |
| `XF86MonBrightnessDown`     | Brightness down 5%              |

---

## Layout Commands

| **Shortcut**       | **Layout**              |
|--------------------|-------------------------|
| `Super + B`        | Horizontal split        |
| `Super + V`        | Vertical split          |
| `Super + S`        | Stacking layout         |
| `Super + W`        | Tabbed layout           |
| `Super + E`        | Toggle split layout     |

---

## Configuration Files

```
~/.config/sway/config              # Main Sway configuration
~/.config/sway/general_keybinds    # General keybindings
~/.config/sway/desktop_keybinds    # Desktop-specific keybinds
~/.config/sway/laptop_keybinds     # Laptop-specific keybinds
~/.config/waybar/config            # Waybar configuration (JSON)
~/.config/waybar/style.css         # Waybar styling
~/.config/foot/foot.ini            # Foot terminal config
~/.config/swaync/config.json       # Notification center config
```

---

## Useful Commands

### System Info
```bash
neofetch                    # System information
htop                        # Process monitor
sensors                     # CPU/GPU temperature
intel_gpu_top               # Intel GPU monitor (requires root)
gpu-stats                   # Custom GPU stats script
```

### Sway Management
```bash
swaymsg reload              # Reload Sway config
swaymsg -t get_outputs      # List displays
swaymsg -t get_inputs       # List input devices
swaymsg -t get_tree         # Window tree
journalctl --user -xe       # Sway logs
```

### Package Management
```bash
sudo apt update             # Update package lists
sudo apt upgrade            # Upgrade packages
sudo apt autoremove         # Remove unused packages
sudo apt clean              # Clean package cache
```

### Audio (PipeWire)
```bash
wpctl status                # Audio status
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%   # Set volume
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle  # Mute toggle
pavucontrol                 # GUI audio mixer
```

### Screenshots
```bash
grim ~/screenshot.png                           # Full screen
grim -g "$(slurp)" ~/screenshot.png             # Selection
grim -g "$(slurp)" - | wl-copy                  # To clipboard
```

### Clipboard
```bash
wl-copy < file.txt          # Copy file to clipboard
wl-paste > file.txt         # Paste clipboard to file
wl-copy "text here"         # Copy text to clipboard
```

---

## Performance Monitoring

### Check RAM Usage
```bash
free -h                     # Memory usage
ps aux --sort=-%mem | head -20   # Top memory consumers
```

### Check CPU Usage
```bash
top                         # Real-time CPU usage
ps aux --sort=-%cpu | head -20   # Top CPU consumers
```

### Intel GPU Stats
```bash
sudo intel_gpu_top          # GPU monitoring (interactive)
cat /sys/class/drm/card0/gt_cur_freq_mhz   # Current GPU freq
glxinfo | grep -i "renderer\|version"      # OpenGL info
vulkaninfo | grep -i "devicename"          # Vulkan info
```

---

## Optimization Tips

### Expected Performance
- **Idle RAM**: ~150-200MB
- **Idle CPU**: <5%
- **GPU Driver**: Intel i965 (Mesa)
- **Audio**: PipeWire (low latency)

### Battery Life (Laptop)
```bash
# Check power state
cat /sys/class/drm/card0/gt_RPn_freq_mhz   # Min GPU freq
cat /sys/class/drm/card0/gt_RP0_freq_mhz   # Max GPU freq

# CPU governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Reduce Resource Usage
- Use Foot instead of heavy terminals (Alacritty, Kitty)
- Keep Waybar modules minimal
- Disable transparency if not needed
- Use `focus_follows_mouse no` (already configured)

---

## Troubleshooting

### Sway Won't Start
```bash
# Check logs
journalctl --user -xe | grep sway

# Test Sway config
sway --validate

# Start Sway manually
sway --debug 2>&1 | tee ~/sway-debug.log
```

### Audio Not Working
```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check audio devices
wpctl status
pavucontrol
```

### Screen Tearing
```bash
# Already configured in /etc/modprobe.d/i915.conf
# Verify kernel parameters
cat /sys/module/i915/parameters/enable_fbc
cat /sys/module/i915/parameters/enable_psr
```

### Font Issues
```bash
# Rebuild font cache
fc-cache -f -v

# List available fonts
fc-list | grep -i "awesome\|dejavu"
```

---

## Gaming Optimizations

### Launch Game with Optimizations
```bash
# With GameMode + MangoHud
gamemoderun mangohud %command%

# With GameScope (Steam game properties)
gamescope -w 1920 -h 1080 -f -- %command%

# Full optimization
gamemoderun gamescope -w 1920 -h 1080 -f -- mangohud %command%
```

### MangoHud Configuration
```bash
# Create config
mkdir -p ~/.config/MangoHud
nano ~/.config/MangoHud/MangoHud.conf

# Minimal overlay
fps
frame_timing=0
cpu_temp
gpu_temp
```

---

## Additional Software

### Install from Flatpak (Optional)
```bash
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Examples
flatpak install flathub com.spotify.Client
flatpak install flathub com.discordapp.Discord
flatpak install flathub org.blender.Blender
```

---

## Backup Important Configs

```bash
# Backup all Sway configs
tar -czf ~/sway-config-backup.tar.gz ~/.config/sway ~/.config/waybar ~/.config/foot ~/.config/swaync

# Restore
tar -xzf ~/sway-config-backup.tar.gz -C ~/
```

---

## References

- **Sway Documentation**: https://github.com/swaywm/sway/wiki
- **Waybar Examples**: https://github.com/Alexays/Waybar/wiki
- **Your GitHub Configs**: https://github.com/BeanGreen247/sway-setup-script
- **Intel Graphics**: https://wiki.archlinux.org/title/intel_graphics
- **PipeWire**: https://wiki.debian.org/PipeWire

---

## Support

For issues or improvements, visit:
- GitHub: https://github.com/BeanGreen247/sway-setup-script
- Sway IRC: #sway on libera.chat
- Debian Forums: https://forums.debian.net/

---

**Created**: February 2026  
**Target**: Debian 13+ (Trixie)  
**Hardware**: Intel i5-6500T (HD 530 iGPU)
