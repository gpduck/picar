#!/usr/bin/env pwsh

Import-Module PiTouchScreen -Force
$b = Get-LocationBrightness
Set-PiTSBrightness $b