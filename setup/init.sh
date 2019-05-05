#!/bin/bash

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
