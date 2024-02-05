#!/bin/bash
# tested on intel hd graphics (intel hd 4000)
$user='user_name_here'
$pass='password_here'
echo $pass | sudo -S apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland mesa-utils libglu1-mesa-dev firefox-esr pcmanfm pulseaudio pavucontrol glmark2 neofetch curl pkexec xterm zenity libcurl4 xbitmaps libutempter0 luit zenity-common libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 mate-polkit libc6-i386 gamemode xarchiver unzip p7zip mangohud goverlay libglu1-mesa:i386 libglu1-mesa waybar fonts-font-awesome intel-gpu-tools intel-acm intel-cmt-cat intel-hdcp intel-media-va-driver-non-free intel-microcode intel-mkl intel-mkl-full intel-opencl-icd wget curl 
### apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland mesa-utils libglu1-mesa-dev firefox-esr pcmanfm pulseaudio pavucontrol glmark2 neofetch curl pkexec xterm zenity libcurl4 xbitmaps libutempter0 luit zenity-common libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 mate-polkit libc6-i386 gamemode xarchiver unzip p7zip mangohud goverlay libglu1-mesa:i386 libglu1-mesa waybar fonts-font-awesome intel-gpu-tools intel-acm intel-cmt-cat intel-hdcp intel-media-va-driver-non-free intel-microcode intel-mkl intel-mkl-full intel-opencl-icd wget curl nvidia-xconfig nvidia-driver nvidia-driver-libs nvidia-vulkan-common nvidia-vulkan-icd nvidia-settings nvidia-powerd nvidia-kernel-dkms nvidia-vaapi-driver nvidia-vdpau-driver nvidia-modprobe nvidia-egl-icd nvidia-egl-common nvidia-opencl-common nvidia-opencl-icd nvidia-fs-dkms nvidia-libopencl1
mkdir -p /home/$user/.config/sway/
wget -O /home/$user/.config/sway/config https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/config
echo $pass | sudo -S dpkg --add-architecture i386
echo $pass | sudo -S apt update
echo $pass | sudo -S apt install -y libgl1:i386
echo $pass | sudo -S apt install -y libc6:amd64 libc6:i386 libegl1:amd64 libegl1:i386 libgbm1:amd64 libgbm1:i386 libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1:amd64 libgl1:i386 steam-libs-amd64:amd64 steam-libs-i386:i386
