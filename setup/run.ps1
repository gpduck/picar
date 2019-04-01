#!/usr/bin/env pwsh
sudo /home/pi/openauto/bin/autoapp
$SSID = iwgetid --raw
if($SSID -eq "SSIDVALUE") {
	sudo shutdown now
} else {
	bash -c "lxpanel --profile LXDE-pi &"
	pcmanfm --desktop --profile LXDE-pi
	xscreensaver -no-splash
}
