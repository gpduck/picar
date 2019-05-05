function Enable-PiTSBacklight {
    Set-Content -Value 0 -Path /sys/class/backlight/rpi_backlight/bl_power
}

function Disable-PiTSBacklight {
    Set-Content -Value 1 -Path /sys/class/backlight/rpi_backlight/bl_power
}

function Get-PiTSBrightness {
    Get-Content -Path /sys/class/backlight/rpi_backlight/brightness
}

function Set-PiTSBrightness {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(0,255)]
        [int32]$Level
    )
    Set-Content -Value $Level -Path /sys/class/backlight/rpi_backlight/brightness
}

function Get-LocationBrightness {
    $Location = Get-Content -Raw /etc/picar/location.json | ConvertFrom-Json
    Import-Module Astro -Force
    $Now = [DateTime]::Now
    $Sunrise = Get-Sunrise -Latitude $Location.Latitude -Longitude $Location.Longitude
    $Sunset = Get-Sunset -Latitude $Location.Latitude -Longitude $Location.Longitude
    if($Now -lt $Sunrise -or $Now -gt $Sunset) {
        128
    } else {
        255
    }
}