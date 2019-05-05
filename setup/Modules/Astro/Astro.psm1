function Get-JulianDay {
    param(
        [DateTime]$Date = [DateTime]::Now
    )
    $Date.ToUniversalTime().ToOADate() + 2415018.5
}

function Get-JulianCentury {
    param(
        $JulianDay
    )
    ($JulianDay - 2451545) / 36525
}

function Get-MeanLongSun {
    param(
        $JulianCentury
    )
    (280.46646 + $JulianCentury * (36000.76983 + $JulianCentury * 0.0003032)) % 360
}

function Get-MeanAnomSun {
    param(
        $JulianCentury
    )
    357.52911 + $JulianCentury * (35999.05029 - 0.0001537 * $JulianCentury)
}

#Q2
function Get-MeanObliqEcliptic {
    param(
        $JulianCentury
    )
    23 + (26 + ((21.448 - $JulianCentury * (46.815 + $JulianCentury * (0.00059 - $JulianCentury * 0.001813))))/60)/60
}

#R2
function Get-Obliqcorr {
    param(
        $MeanObliqEcliptic,   #Q2
        $JulianCentury        #G2
    )
    $MeanObliqEcliptic + 0.00256 * [Math]::Cos((RADIANS 125.04 - 1934.136 * $JulianCentury))
}

function Degrees {
    param(
        $Radians
    )
    (180 / [Math]::Pi) * $Radians
}

function Radians {
    param(
        $Degrees
    )
    $Degrees / (180 / [Math]::Pi)
}

#K2
function Get-EccentEarthOrbit {
    param(
        $JulianCentury
    )
    0.016708634 - $JulianCentury * (0.000042037 + 0.0000001267 * $JulianCentury)
}

#L2
function Get-SunEqOfCtr {
    param(
        $MeanAnomSun,      #J2
        $JulianCentury     #G2
    )
    <#
    SIN(RADIANS(J2)) * (1.914602-G2*(0.004817+0.000014*G2))
    +
    SIN(RADIANS(2*J2)) * (0.019993-0.000101*G2)
    +
    SIN(RADIANS(3*J2))*0.000289
    #>
    $P1 = [Math]::Sin((RADIANS $MeanAnomSun)) * (1.914602 - $JulianCentury * (0.004817 + 0.000014 * $JulianCentury))
    $P2 = [Math]::Sin((RADIANS (2 * $MeanAnomSun))) * (0.019993 - 0.000101 * $JulianCentury)
    $P3 = [Math]::Sin((RADIANS (3 * $MeanAnomSun))) * 0.000289
    $P1 + $P2 + $P3
}

#M2
function Get-SunTrueLong {
    param(
        $GeomMeanLongSun,   #I2
        $SunEqOfCtr         #L2
    )
    $GeomMeanLongSun + $SunEqOfCtr
}

#P2
function Get-SunAppLong {
    param(
        $SunTrueLong,    #M2
        $JulianCentury   #G2
    )
    $SunTrueLong - 0.00569 - 0.00478 * [Math]::Sin((RADIANS (125.04 - 1934.136 * $JulianCentury)))
}

#T2
function Get-SunDeclin {
    param(
        $ObliqCorr,   #R2
        $SunAppLong   #P2
    )
    $P1 = [Math]::Sin((RADIANS $ObliqCorr)) * [Math]::Sin((RADIANS $SunAppLong))
    DEGREES ([Math]::ASin($P1))
}

#U2
function Get-VarY {
    param(
        $ObliqCorr    #R2
    )
    $P1 = RADIANS ($ObliqCorr / 2)
    [Math]::Tan($P1) * [Math]::Tan($P1)
}

#V2
function Get-EqOfTime {
    param(
        $VarY,              #U2
        $MeanLongSun,       #I2
        $EccentEarthOrbit,  #K2
        $MeanAnomSun        #J2
    )
    <#
    4*DEGREES(
        U2 * SIN(2*RADIANS(I2))
        -
        2*K2*SIN(RADIANS(J2))
        +
        4*K2*U2*SIN(RADIANS(J2))*COS(2*RADIANS(I2))
        -
        0.5*U2*U2*SIN(4*RADIANS(I2))
        -
        1.25*K2*K2*SIN(2*RADIANS(J2))
    )
    #>
    $P1 = $VarY * [Math]::Sin(2 * (RADIANS $MeanLongSun))
    $P2 = 2 * $EccentEarthOrbit * [Math]::Sin((RADIANS $MeanAnomSun))
    $P3 = 4 * $EccentEarthOrbit * $VarY * [Math]::Sin((RADIANS $MeanAnomSun)) * [Math]::Cos(2 * (RADIANS $MeanLongSun))
    $P4 = 0.5 * $VarY * $VarY * [Math]::Sin(4 * (RADIANS $MeanLongSun))
    $P5 = 1.25 * $EccentEarthOrbit * $EccentEarthOrbit * [Math]::Sin(2 * (RADIANS $MeanAnomSun))
    4 * (DEGREES ($P1 - $P2 + $P3 - $P4 - $P5))
}

#W2
function Get-HASunrise {
    param(
        $Latitude,     #B3
        $SunDeclin     #T2
    )
    <#
    DEGREES(
        ACOS(
            COS(RADIANS(90.833)) / (COS(RADIANS($B$3)) * COS(RADIANS(T2)))
            -
            TAN(RADIANS($B$3)) * TAN(RADIANS(T2))
        )
    )
    #>
    $P1 = [Math]::Cos((RADIANS 90.833)) / [Math]::Cos((RADIANS $Latitude)) * [Math]::Cos((RADIANS $SunDeclin))
    $P2 = [Math]::Tan((RADIANS $Latitude)) * [Math]::Tan((RADIANS $SunDeclin))
    DEGREES ([Math]::ACos( $P1 - $P2 ))
}

#X2
function Get-SolarNoon {
    param(
        [Int]$Longitude,       #B4
        [Int]$TimezoneOffset,  #B5
        $EqOfTime         #V2
    )
    (720 - 4 * $Longitude - $EqOfTime + $TimezoneOffset * 60) / 1440
}

#Y2
function Get-SunriseTime {
    param(
        $SolarNoon,  #X2
        $HASunrise   #W2
    )
    $SolarNoon - $HASunrise * 4 / 1440
}

#Z2
function Get-SunsetTime {
    param(
      $SolarNoon,  #X2
      $HASunrise   #W2
    )
    $SolarNoon + $HASunrise * 4 / 1440
}

function Get-Sunset {
    param(
        [Parameter(Mandatory=$true)]
        $Latitude,

        [Parameter(Mandatory=$true)]
        $Longitude,

        [DateTime]$Date = ([DateTime]::Now),

        $TimezoneOffset = ([System.TimeZone]::CurrentTimeZone.GetUtcOffset($Date).Hours)
    )
    $JulianDay = Get-JulianDay $Date
    $JulianCentury = Get-JulianCentury $JulianDay
    $MeanAnomSun = Get-MeanAnomSun $JulianCentury
    $EccentEarthOrbit = Get-EccentEarthOrbit $JulianCentury
    $MeanLongSun = Get-MeanLongSun $JulianCentury
    $MeanObliqEcliptic = Get-MeanObliqEcliptic $JulianCentury
    $ObliqCorr = Get-ObliqCorr $MeanObliqEcliptic $JulianCentury
    $VarY = Get-VarY $ObliqCorr
    $EqOfTime = Get-EqOfTime $VarY $MeanLongSun $EccentEarthOrbit $MeanAnomSun
    $SolarNoon = Get-SolarNoon $Longitude $TimezoneOffset $EqOfTime

    $SunEqOfCtr = Get-SunEqOfCtr $MeanAnomSun $JulianCentury
    $SunTrueLong = Get-SunTrueLong $MeanLongSun $SunEqOfCtr
    $SunAppLong = Get-SunAppLong $SunTrueLong $JulianCentury
    $SunDeclin = Get-SunDeclin $ObliqCorr $SunAppLong
    $HASunrise = Get-HASunrise $Latitude $SunDeclin

    $SunsetTime = Get-SunsetTime $SolarNoon $HASunrise
    $Date.Date.AddHours(24 * $SunsetTime)
}

function Get-Sunrise {
    param(
        [Parameter(Mandatory=$true)]
        $Latitude,

        [Parameter(Mandatory=$true)]
        $Longitude,

        [DateTime]$Date = ([DateTime]::Now),

        $TimezoneOffset = ([System.TimeZone]::CurrentTimeZone.GetUtcOffset($Date).Hours)
    )
    $JulianDay = Get-JulianDay $Date
    $JulianCentury = Get-JulianCentury $JulianDay
    $MeanAnomSun = Get-MeanAnomSun $JulianCentury
    $EccentEarthOrbit = Get-EccentEarthOrbit $JulianCentury
    $MeanLongSun = Get-MeanLongSun $JulianCentury
    $MeanObliqEcliptic = Get-MeanObliqEcliptic $JulianCentury
    $ObliqCorr = Get-ObliqCorr $MeanObliqEcliptic $JulianCentury
    $VarY = Get-VarY $ObliqCorr
    $EqOfTime = Get-EqOfTime $VarY $MeanLongSun $EccentEarthOrbit $MeanAnomSun
    $SolarNoon = Get-SolarNoon $Longitude $TimezoneOffset $EqOfTime

    $SunEqOfCtr = Get-SunEqOfCtr $MeanAnomSun $JulianCentury
    $SunTrueLong = Get-SunTrueLong $MeanLongSun $SunEqOfCtr
    $SunAppLong = Get-SunAppLong $SunTrueLong $JulianCentury
    $SunDeclin = Get-SunDeclin $ObliqCorr $SunAppLong
    $HASunrise = Get-HASunrise $Latitude $SunDeclin

    $SunriseTime = Get-SunriseTime $SolarNoon $HASunrise
    $Date.Date.AddHours(24 * $SunriseTime)
}

<#

$Day = [DateTime]"5/5/2019"

$Values = [Ordered]@{}
$Values["F2"] = Get-JulianDay $Day
$Values["G2"] = Get-JulianCentury $Values["F2"]
$Values["I2"] = Get-MeanLongSun $Values["G2"]
$Values["J2"] = Get-MeanAnomSun $Values["G2"]
$Values["K2"] = Get-EccentEarthOrbit $Values["G2"]
$Values["Q2"] = Get-MeanObliqEcliptic $Values["G2"]
$Values["R2"] = Get-ObliqCorr $Values["Q2"] $Values["G2"]
$Values["U2"] = Get-VarY $Values["R2"]
$Values["V2"] = Get-EqOfTime $Values["U2"] $Values["I2"] $Values["K2"] $Values["J2"]
$Values["X2"] = Get-SolarNoon -88 -5 $Values["V2"]
$Values["L2"] = Get-SunEqOfCtr  $Values["J2"] $Values["G2"]
$Values["M2"] = Get-SunTrueLong $Values["I2"] $Values["L2"]
$Values["P2"] = Get-SunAppLong $Values["M2"] $Values["G2"]
$Values["T2"] = Get-SunDeclin $Values["R2"] $Values["P2"]
$Values["W2"] = Get-HASunrise 41.6 $Values["T2"]
$Values["Y2"] = Get-SunriseTime $Values["X2"] $Values["W2"]
$Values["Z2"] = Get-SunsetTime $Values["X2"] $Values["W2"]

[PSCustomObject]$Values

$Sunrise = $Day.AddHours(24 * $Values["Y2"])
$Sunset = $Day.AddHours(24 * $Values["Z2"])
$Sunrise
$Sunset

#>