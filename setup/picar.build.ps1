


task . Build-AASDK,Build-OpenAuto,RemoveExtraPackages,Install-TwoFing,Configure-TwoFing,CopyFiles,UpdateSSID,UpdateGraphics

task Update Build-AASDK,Build-OpenAuto


task Build-AASDK {
    # Build aasdk
    pushd ~
        sudo apt-get install -y libboost-all-dev libusb-1.0-0-dev libssl-dev cmake libprotobuf-dev protobuf-c-compiler protobuf-compiler
        if(!(Test-Path ./aasdk)) {
            git clone -b master https://github.com/f1xpl/aasdk.git
        } else {
            pushd aasdk
                git pull
            popd
        }
        if(!(Test-Path ./aasdk_build)) {
            mkdir aasdk_build
        }
        pushd aasdk_build
            cmake -DCMAKE_BUILD_TYPE=Release ../aasdk
            make
        popd
    popd
}

task Build-OpenAuto Build-AASDK,{
    sudo apt-get install -y libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediawidgets5 qtmultimedia5-dev libqt5bluetooth5 libqt5bluetooth5-bin qtconnectivity5-dev pulseaudio librtaudio-dev librtaudio5a
    pushd /opt/vc/src/hello_pi/libs/ilclient
        make
    popd
    pushd ~
        if(!(Test-Path ./openauto)) {
            #git clone -b master https://github.com/f1xpl/openauto.git
            git clone -b development https://github.com/Oper92/openauto
        } else {
            pushd openauto
                git pull
            popd
        }
        if(!(Test-Path ./openauto_build)) {
            mkdir openauto_build
        }
        pushd openauto_build
            cmake -DCMAKE_BUILD_TYPE=Release -DRPI3_BUILD=TRUE -DAASDK_INCLUDE_DIRS="/home/pi/aasdk/include" -DAASDK_LIBRARIES="/home/pi/aasdk/lib/libaasdk.so" -DAASDK_PROTO_INCLUDE_DIRS="/home/pi/aasdk_build" -DAASDK_PROTO_LIBRARIES="/home/pi/aasdk/lib/libaasdk_proto.so" ../openauto
            make
        popd
    popd
}

task RemoveExtraPackages {
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
}

task Install-TwoFing {
    # Install twofing
    #   http://plippo.de/p/twofing
    sudo apt-get install build-essential libx11-dev libxtst-dev libxi-dev x11proto-randr-dev libxrandr-dev xserver-xorg-input-evdev
    pushd ~
        if(!(Test-Path ./twofing)) {
            git clone https://github.com/Plippo/twofing
        } else {
            pushd twofing
                git pull
            popd
        }
        pushd twofing
            make
            sudo make install
        popd
    popd
}

task Configure-TwoFing Install-TwoFing,{
    sudo sed -i '$ a Section "InputClass"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a     Identifier "calibration"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a     Driver "evdev"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a     matchProduct "FT5406 memory based driver"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a     Option "EmulateThirdButton" "1"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a     Option "EmulateThirdButtonTimeout" "750"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a     Option "EmulateThirdButtonMoveThreshold" "30"' -i /usr/share/X11/xorg.conf.d/10-evdev.conf
    sudo sed -i '$ a EndSection' -i /usr/share/X11/xorg.conf.d/10-evdev.conf

    sudo cp $BUILDROOT/70-touchscreen-raspberrypi.rules /etc/udev/rules.d/
}

task CopyFiles {
    # Copy files
    mkdir -p ~/.config/lxsession/LXDE-pi/
    cp $BUILDROOT/autostart ~/.config/lxsession/LXDE-pi/autostart
    sudo cp $BUILDROOT/openauto_wifi_recent.ini ~/
    sudo cp $BUILDROOT/icons/* /usr/share/pixmaps/
    cp $BUILDROOT/apps/* ~/.local/share/applications/
    cp $BUILDROOT/directories/* ~/.local/share/desktop-directories/
    cp $BUILDROOT/panel ~/.config/lxpanel/LXDE-pi/panels/panel
    sudo cp $BUILDROOT/lxde-pi-applications.menu ~/.config/menus/lxde-pi-applications.menu
    cp $BUILDROOT/*.ps1 ~/
    dir ~/*.ps1 | ForEach-Object {
        sudo chmod +x $_.Fullname
    }
}

task UpdateSSID CopyFiles,{
    # Customize PI
    $SSID = Read-Host -Prompt "Car SSID"
    $PSK = Read-Host -Prompt "Car PSK"

    sed "s/SSIDVALUE/$SSID/g" -i ~/run.ps1

    sudo sed -i "\$ a \nnetwork={\n    ssid=\"$SSID\"\n    psk=\"$PSK\"\n    key_mgmt=WPA-PSK\n    priority=1\n}" -i /etc/wpa_supplicant/wpa_supplicant.conf
}

task SetLocation {
    $Latitude = Read-Host -Prompt "Latitude"
    $Longitude = Read-host -Prompt "Longitude"
    $Location = [PSCustomObject]@{
        Latitude = [float]$Latitude
        Longitude = [float]$Longitude
    }
    if(!(Test-Path /etc/picar)) {
        sudo mkdir -p /etc/picar
    }
    Set-Content -Path /tmp/location.json -Value (ConvertTo-Json $Location)
    sudo cp /tmp/location.json /etc/picar/location.json
    sudo cp $BUILDROOT/picar.cron /etc/cron.d/picar
}

task UpdateGraphics {
    sudo sed -i '$ a gpu_mem=256' -i /boot/config.txt
    sudo sed -i '$ a disable_splash=1' -i /boot/config.txt
    sudo sed -i '1 s/$/ logo.nologo/' -i /boot/cmdline.txt

    # Set wallpaper
    #   https://yingtongli.me/blog/2016/12/21/splash.html
    sudo cp /home/pi/setup/splash.png /usr/share/plymouth/themes/pix/splash.png
    DISPLAY=:0 pcmanfm --set-wallpaper="/home/pi/setup/wallpaper.jpg"
}

task CopyModules {
    if(!(Test-Path /usr/local/share/powershell/Modules)) {
        sudo mkdir -p /usr/local/share/powershell/Modules
    }
    sudo cp -r $BUILDROOT/Modules /usr/local/share/powershell/
}

task ScheduleTasks {

}