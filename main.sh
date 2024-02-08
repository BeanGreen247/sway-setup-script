#!/bin/bash
# tested on intel hd graphics (intel hd 4000)
$user='user_name_here'
sudo bash sources_list_setup.sh
sudo apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland mesa-utils libglu1-mesa-dev firefox-esr pcmanfm pulseaudio pavucontrol glmark2 neofetch curl pkexec xterm zenity libcurl4 xbitmaps libutempter0 luit zenity-common libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 mate-polkit libc6-i386 gamemode xarchiver unzip p7zip mangohud goverlay libglu1-mesa:i386 libglu1-mesa waybar fonts-font-awesome intel-gpu-tools intel-acm intel-cmt-cat intel-hdcp intel-media-va-driver-non-free intel-microcode intel-mkl intel-mkl-full intel-opencl-icd wget curl wl-clipboard grim slurp ttf-mscorefonts-installer fonts-dseg texlive-fonts-recommended texlive-fonts-extra
### apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland mesa-utils libglu1-mesa-dev firefox-esr pcmanfm pulseaudio pavucontrol glmark2 neofetch curl pkexec xterm zenity libcurl4 xbitmaps libutempter0 luit zenity-common libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 mate-polkit libc6-i386 gamemode xarchiver unzip p7zip mangohud goverlay libglu1-mesa:i386 libglu1-mesa waybar fonts-font-awesome intel-gpu-tools intel-acm intel-cmt-cat intel-hdcp intel-media-va-driver-non-free intel-microcode intel-mkl intel-mkl-full intel-opencl-icd wget curl wl-clipboard grim slurp ttf-mscorefonts-installer fonts-dseg texlive-fonts-recommended texlive-fonts-extra nvidia-xconfig nvidia-driver nvidia-driver-libs nvidia-vulkan-common nvidia-vulkan-icd nvidia-settings nvidia-powerd nvidia-kernel-dkms nvidia-vaapi-driver nvidia-vdpau-driver nvidia-modprobe nvidia-egl-icd nvidia-egl-common nvidia-opencl-common nvidia-opencl-icd nvidia-fs-dkms nvidia-libopencl1
sudo apt install fonts-font-awesome -y --reinstall
mkdir -p /home/$user/.config/sway/
wget -O /home/$user/.config/sway/config https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/config
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y libgl1:i386
sudo apt install -y libc6:amd64 libc6:i386 libegl1:amd64 libegl1:i386 libgbm1:amd64 libgbm1:i386 libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1:amd64 libgl1:i386 steam-libs-amd64:amd64 steam-libs-i386:i386
mkdir -p /home/$user/.fonts
rm -rf /home/$user/fontawesome-free-*-desktop* /home/$user/fontawesome-free-*-desktop*.zip
wget https://use.fontawesome.com/releases/v6.5.1/fontawesome-free-6.5.1-desktop.zip ## figure out how to get latest version
unzip fontawesome-free-*-desktop.zip
cp -r /home/$user/fontawesome-free-*-desktop/otfs /usr/local/share/fonts/
mv /home/$user/fontawesome-free-*-desktop/otfs/*.otf /home/$user/.fonts/
rm -rf /home/$user/fontawesome-free-*-desktop* /home/$user/fontawesome-free-*-desktop*.zip
sudo apt clean
mkdir -p /home/$user/.config/waybar
cd .config/waybar/
# waybar config need to look up how to configure
#wget https://raw.githubusercontent.com/-some-null-/config/master/.config/waybar/config
#wget https://raw.githubusercontent.com/-some-null-/config/master/.config/waybar/style.css
#bean@t430:~$ nano .config/waybar/config 
#bean@t430:~$ nano .config/waybar/style.css
#
echo "make sure to run 'fc-cache -f -v' after install script has finished"
