#!/bin/bash
# tested on intel hd graphics (intel hd 4000)
user='user_name_here'
sudo bash sources_list_setup.sh
# NOTE remove duplicates
sudo apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland mesa-utils libglu1-mesa-dev firefox-esr pcmanfm pulseaudio pavucontrol glmark2 neofetch curl pkexec xterm zenity libcurl4 xbitmaps libutempter0 luit zenity-common libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 mate-polkit libc6-i386 gamemode xarchiver unzip p7zip mangohud goverlay libglu1-mesa:i386 libglu1-mesa waybar fonts-font-awesome intel-gpu-tools intel-acm intel-cmt-cat intel-hdcp intel-media-va-driver-non-free intel-microcode intel-mkl intel-mkl-full intel-opencl-icd wget curl wl-clipboard grim slurp ttf-mscorefonts-installer fonts-dseg texlive-fonts-recommended texlive-fonts-extra lxappearance vim brightnessctl tree libsdl2-dev libogg-dev flex bison steam ca-certificates git build-essential cmake gcc g++ libkf5config-dev libkf5auth-dev libkf5package-dev libkf5declarative-dev libkf5coreaddons-dev libkf5dbusaddons-dev libkf5kcmutils-dev libkf5i18n-dev libkf5plasma-dev libqt5core5a libqt5widgets5 libqt5gui5 libqt5qml5 extra-cmake-modules qtbase5-dev libkf5notifications-dev qml-module-org-kde-kirigami2 qml-module-qtquick-dialogs qml-module-qtquick-controls2 qml-module-qtquick-layouts qml-module-qt-labs-settings qml-module-qt-labs-folderlistmodel gettext fancontrol lm-sensors qttools5-dev-tools
### apt install -y sway swaybg swayidle swaylock xdg-desktop-portal-wlr xwayland mesa-utils libglu1-mesa-dev firefox-esr pcmanfm pulseaudio pavucontrol glmark2 neofetch curl pkexec xterm zenity libcurl4 xbitmaps libutempter0 luit zenity-common libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 mate-polkit libc6-i386 gamemode xarchiver unzip p7zip mangohud goverlay libglu1-mesa:i386 libglu1-mesa waybar fonts-font-awesome intel-gpu-tools intel-acm intel-cmt-cat intel-hdcp intel-media-va-driver-non-free intel-microcode intel-mkl intel-mkl-full intel-opencl-icd wget curl wl-clipboard grim slurp ttf-mscorefonts-installer fonts-dseg texlive-fonts-recommended texlive-fonts-extra lxappearance vim brightnessctl tree libsdl2-dev libogg-dev flex bison steam ca-certificates git build-essential cmake gcc g++ libkf5config-dev libkf5auth-dev libkf5package-dev libkf5declarative-dev libkf5coreaddons-dev libkf5dbusaddons-dev libkf5kcmutils-dev libkf5i18n-dev libkf5plasma-dev libqt5core5a libqt5widgets5 libqt5gui5 libqt5qml5 extra-cmake-modules qtbase5-dev libkf5notifications-dev qml-module-org-kde-kirigami2 qml-module-qtquick-dialogs qml-module-qtquick-controls2 qml-module-qtquick-layouts qml-module-qt-labs-settings qml-module-qt-labs-folderlistmodel gettext fancontrol lm-sensors qttools5-dev-tools nvidia-xconfig nvidia-driver nvidia-driver-libs nvidia-vulkan-common nvidia-vulkan-icd nvidia-settings nvidia-powerd nvidia-kernel-dkms nvidia-vaapi-driver nvidia-vdpau-driver nvidia-modprobe nvidia-egl-icd nvidia-egl-common nvidia-opencl-common nvidia-opencl-icd nvidia-fs-dkms nvidia-libopencl1
sudo apt install fonts-font-awesome -y --reinstall
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y libgl1:i386
sudo apt install -y libc6:amd64 libc6:i386 libegl1:amd64 libegl1:i386 libgbm1:amd64 libgbm1:i386 libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1:amd64 libgl1:i386 steam-libs-amd64:amd64 steam-libs-i386:i386
# more tools
sudo apt-get install ca-certificates git build-essential cmake gcc g++ libkf5config-dev libkf5auth-dev libkf5package-dev libkf5declarative-dev libkf5coreaddons-dev libkf5dbusaddons-dev libkf5kcmutils-dev libkf5i18n-dev libkf5plasma-dev libqt5core5a libqt5widgets5 libqt5gui5 libqt5qml5 extra-cmake-modules qtbase5-dev libkf5notifications-dev qml-module-org-kde-kirigami2 qml-module-qtquick-dialogs qml-module-qtquick-controls2 qml-module-qtquick-layouts qml-module-qt-labs-settings qml-module-qt-labs-folderlistmodel gettext
# fonts
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
wget -O /home/$user/.config/waybar/config https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/waybar/config
wget -O /home/$user/.config/waybar/style.css https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/waybar/style.css
mkdir -p /home/$user/.config/sway/
cd .config/sway/
wget -O /home/$user/.config/sway/config https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/config
wget -O /home/$user/.config/sway/general_keybinds https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/general_keybinds
wget -O /home/$user/.config/sway/desktop_keybinds https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/desktop_keybinds
wget -O /home/$user/.config/sway/laptop_keybinds https://raw.githubusercontent.com/BeanGreen247/sway-setup-script/main/sway/laptop_keybinds
echo "make sure to run 'fc-cache -f -v' after install script has finished"
