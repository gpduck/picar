#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Build aasdk
pushd ~
  sudo apt-get install -y libboost-all-dev libusb-1.0-0-dev libssl-dev cmake libprotobuf-dev protobuf-c-compiler protobuf-compiler
  git clone -b master https://github.com/f1xpl/aasdk.git
  mkdir aasdk_build
  pushd aasdk_build
    cmake -DCMAKE_BUILD_TYPE=Release ../aasdk
    make
  popd
popd

# Build openauto
sudo apt-get install -y libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediawidgets5 qtmultimedia5-dev libqt5bluetooth5 libqt5bluetooth5-bin qtconnectivity5-dev pulseaudio librtaudio-dev librtaudio5a
pushd /opt/vc/src/hello_pi/libs/ilclient
  make
popd
pushd ~
  #git clone -b master https://github.com/f1xpl/openauto.git
  git clone -b development https://github.com/Oper92/openauto
  mkdir openauto_build
  pushd openauto_build
    cmake -DCMAKE_BUILD_TYPE=Release -DRPI3_BUILD=TRUE -DAASDK_INCLUDE_DIRS="/home/pi/aasdk/include" -DAASDK_LIBRARIES="/home/pi/aasdk/lib/libaasdk.so" -DAASDK_PROTO_INCLUDE_DIRS="/home/pi/aasdk_build" -DAASDK_PROTO_LIBRARIES="/home/pi/aasdk/lib/libaasdk_proto.so" ../openauto
    make
  popd
popd

# Install PowerShell
PSFILE=powershell-6.2.0-linux-arm32.tar.gz
sudo apt-get install libunwind8
pushd ~
  wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/$PSFILE
  sudo mkdir -p /opt/microsoft/powershell/6
  sudo tar -xvf ./$PSFILE -C /opt/microsoft/powershell/6
  sudo chmod +x /opt/microsoft/powershell/6/pwsh
  sudo ln -s /opt/microsoft/powershell/6/pwsh /usr/bin/pwsh
  rm $PSFILE
popd

# Remove extra packages
sudo apt remove -y \
    chromium-browser \
    chromium-browser-l10n \
    chromium-codecs-ffmpeg-extra \
    rpi-chromium-mods \
    geany \
    geany-common \
    idle \
    idle-python2.7 \
    idle-python3.5 \
    idle3

# Install twofing
#   http://plippo.de/p/twofing
sudo apt-get install build-essential libx11-dev libxtst-dev libxi-dev x11proto-randr-dev libxrandr-dev xserver-xorg-input-evdev
pushd ~
  git clone https://github.com/Plippo/twofing
  pushd twofing
    make
    sudo make install
  popd
popd

sudo sed -i '$ a Section "InputClass"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a     Identifier "calibration"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a     Driver "evdev"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a     matchProduct "FT5406 memory based driver"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a     Option "EmulateThirdButton" "1"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a     Option "EmulateThirdButtonTimeout" "750"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a     Option "EmulateThirdButtonMoveThreshold" "30"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
sudo sed -i '$ a EndSection' -i /usr/share/X11/xorg.conf.d/10-evdev.conf

sudo cp $DIR/70-touchscreen-raspberrypi.rules /etc/udev/rules.d/

# Copy files
mkdir -p ~/.config/lxsession/LXDE-pi/
cp $DIR/autostart ~/.config/lxsession/LXDE-pi/autostart
sudo cp $DIR/openauto_wifi_recent.ini ~/
sudo cp $DIR/icons/* /usr/share/pixmaps/
cp $DIR/apps/* ~/.local/share/applications/
cp $DIR/directories/* ~/.local/share/desktop-directories/
cp $DIR/panel ~/.config/lxpanel/LXDE-pi/panels/panel
sudo cp $DIR/lxde-pi-applications.menu ~/.config/menus/lxde-pi-applications.menu

# Customize PI
echo -n "Enter car SSID: "
read SSID
echo -n "Enter car PSK: "
read PSK
cp $DIR/run.ps1 ~/
sed "s/SSIDVALUE/$SSID/g" -i ~/run.ps1

sudo sed -i "\$ a \nnetwork={\n    ssid=\"$SSID\"\n    psk=\"$PSK\"\n    key_mgmt=WPA-PSK\n    priority=1\n}" -i /etc/wpa_supplicant/wpa_supplicant.conf
sudo sed -i '$ a gpu_mem=256' -i /boot/config.txt
sudo sed -i '$ a disable_splash=1' -i /boot/config.txt
sudo sed -i '1 s/$/ logo.nologo/' -i /boot/cmdline.txt

# Set wallpaper
#   https://yingtongli.me/blog/2016/12/21/splash.html
sudo cp /home/pi/setup/splash.png /usr/share/plymouth/themes/pix/splash.png
DISPLAY=:0 pcmanfm --set-wallpaper="/home/pi/setup/wallpaper.jpg"

