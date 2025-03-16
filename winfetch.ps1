#!/usr/bin/env -S pwsh -nop
#requires -version 5

# (!) This file must to be saved in UTF-8 with BOM encoding in order to work with legacy Powershell 5.x

<#PSScriptInfo
.VERSION 2.5.4
.GUID 27c6f0dd-dbf2-4a3e-90df-a23c3c6c630d
.AUTHOR Winfetch contributers
.PROJECTURI https://github.com/lptstr/winfetch
.COMPANYNAME
.COPYRIGHT
.TAGS neofetch screenfetch system-info commandline
.LICENSEURI https://github.com/lptstr/winfetch/blob/master/LICENSE
.ICONURI https://lptstr.github.io/lptstr-images/proj/winfetch/logo.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS
    Winfetch - Neofetch for Windows in PowerShell 5+
.DESCRIPTION
    Winfetch is a command-line system information utility for Windows written in PowerShell.
.PARAMETER image
    Display a pixelated image instead of the usual logo.
.PARAMETER ascii
    Display the image using ASCII characters instead of blocks.
.PARAMETER genconf
    Reset your configuration file to the default.
.PARAMETER configpath
    Specify a path to a custom config file.
.PARAMETER noimage
    Do not display any image or logo; display information only.
.PARAMETER logo
    Sets the version of Windows to derive the logo from.
.PARAMETER imgwidth
    Specify width for image/logo. Default is 35.
.PARAMETER alphathreshold
    Specify minimum alpha value for image pixels to be visible. Default is 50.
.PARAMETER blink
    Make the logo blink.
.PARAMETER stripansi
    Output without any text effects or colors.
.PARAMETER sixel
    Output image using sixel format.
    Not yet implemented!
.PARAMETER timed
    Display the time taken to output each element along with the overhead and total.
.PARAMETER multithreaded
    Use multithreading to run slower functions together like ps_pkgs and pkgs.
    Not yet implemented!
.PARAMETER nooutput
    Hide all output — only load functions for individual use.
.PARAMETER all
    Display all built-in info segments.
.PARAMETER help
    Display this help message.
.PARAMETER cpustyle
    Specify how to show information level for CPU usage
.PARAMETER memorystyle
    Specify how to show information level for RAM usage
.PARAMETER diskstyle
    Specify how to show information level for disks' usage
.PARAMETER batterystyle
    Specify how to show information level for battery
.PARAMETER showdisks
    Configure which disks are shown, use '-showdisks *' to show all.
.PARAMETER showpkgs
    Configure which package managers are shown, e.g. '-showpkgs winget,scoop,choco'.
.INPUTS
    System.String
.OUTPUTS
    System.String[]
.NOTES
    Run Winfetch without arguments to view core functionality.
#>
[CmdletBinding()]
param(
    [string][alias('i')]$image,
    [switch][alias('k')]$ascii,
    [switch][alias('g')]$genconf,
    [string][alias('c')]$configpath,
    [switch][alias('n')]$noimage,
    [string][alias('l')]$logo,
    [switch][alias('b')]$blink,
    [switch][alias('s')]$stripansi,
    # NOTE: This parameter will depend on the terminal being used, and having an img2sixel build.
    # https://www.arewesixelyet.com has a list of terminals that support sixel.
    # Windows Terminal supports sixel as of Preview 1.22.
    [Parameter(DontShow)][switch][alias('x')]$sixel,
    [switch][alias('e')]$timed,
    [switch][alias('m')]$multithreaded,
    # dynamically fit info_dashes to the previous line
    [switch][alias('d')]$fitdashes,
    # loads functions but does not output anything
    [switch][alias('n')]$nooutput,
    [switch][alias('a')]$all,
    [switch][alias('h')]$help,
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$cpustyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$memorystyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$diskstyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$batterystyle = "text",
    [ValidateScript({ $_ -gt 1 -and $_ -lt $Host.UI.RawUI.WindowSize.Width - 1 })][alias('w')][int]$imgwidth = 35,
    [byte][alias('t')]$alphathreshold = 50,
    [array]$showdisks = @($env:SystemDrive),
    [array]$showpkgs = @("scoop", "choco")
)

if (-not ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5)) {
    Write-Error "Only supported on Windows."
    exit 1
}

$script:VERBOSE = $PSBoundParameters.ContainsKey('Verbose')

# ===== DISPLAY HELP =====
if ($help -and !$nooutput) {
    if (Get-Command -Name less -ErrorAction Ignore) {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full | less
    } else {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full
    }
    exit 0
}

#region: Configuration
# Start global timer
$sw1 = [System.Diagnostics.Stopwatch]::StartNew()

# ===== CONFIG MANAGEMENT =====
$defaultConfig = @'
# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Display image using ASCII characters
# $ascii = $true

# Set the version of Windows to derive the logo from.
# $logo = "Windows 10"

# Specify width for image/logo
# $imgwidth = 24

# Specify minimum alpha value for image pixels to be visible
# $alphathreshold = 50

# Custom ASCII Art
# This should be an array of strings, with positive
# height and width equal to $imgwidth defined above.
# $CustomAscii = @(
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣦⠀  "
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣶⣾⣷⣶⣆⠸⣿⣿⡟⠀  "
#     "⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣷⡈⠻⠿⠟⠻⠿⢿⣷⣤⣤⣄⠀⠀  "
#     "⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣦⠀  "
#     "⠀⠀⠀⢀⣤⣤⡘⢿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⡇  "
#     "⠀⠀⠀⣿⣿⣿⡇⢸⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⣉⣉⡁  "
#     "⠀⠀⠀⠈⠛⠛⢡⣾⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⡇  "
#     "⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⠟⠀  "
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡿⢁⣴⣶⣦⣴⣶⣾⡿⠛⠛⠋⠀⠀  "
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠿⠿⢿⡿⠿⠏⢰⣿⣿⣧⠀⠀  "
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⠟⠀⠀  "
# )

# Make the logo blink
# $blink = $true

# Display all built-in info segments.
# $all = $true

# Add a custom info line
# function info_custom_time {
#     return @{
#         title = "Time"
#         content = (Get-Date)
#     }
# }

# Configure which disks are shown
# $ShowDisks = @("C:", "D:")
# Show all available disks
# $ShowDisks = @("*")

# Configure which package managers are shown
# disabling unused ones will improve speed
# $ShowPkgs = @("winget", "scoop", "choco")

# Use the following option to specify custom package managers.
# Create a function with that name as suffix, and which returns
# the number of packages. Two examples are shown here:
# $CustomPkgs = @("cargo", "just-install")
# function info_pkg_cargo {
#     return (cargo install --list | Where-Object {$_ -like "*:" }).Length
# }
# function info_pkg_just-install {
#     return (just-install list).Length
# }

# Configure how to show info for levels
# Default is for text only, i.e.    CPU Usage: 253 processes
# 'bar' is for bar only, i.e.       Memory: [ ■■■■------ ]
# 'bartext' is for bar + text, i.e. Memory: [ ■■■■------ ] 7.17 GiB / 16 GiB
# 'textbar' is for text + bar, i.e. CPU Usage: 297 processes [ ■■■------- ]
# $cpustyle = 'bar'
# $memorystyle = 'textbar'
# $diskstyle = 'bartext'
# $batterystyle = 'bartext'

# Remove the '#' from any of the lines in
# the following to **enable** their output.

@(
    "title"
    "dashes"
    "os"
    "computer"
    "kernel"
    "motherboard"
    # "custom_time"  # use custom info line
    "uptime"
    # "ps_pkgs"  # takes some time
    "pkgs"
    "pwsh"
    "resolution"
    "terminal"
    # "theme"
    "cpu"
    "gpu"
    # "cpu_usage"
    "memory"
    "disk"
    # "battery"
    "locale"
    # "timezone"
    # "weather"
    # "local_ip"
    # "public_ip"
    "blank"
    "colorbar"
)

'@

if (-not $configPath) {
    if ($env:WINFETCH_CONFIG_PATH) {
        $configPath = $env:WINFETCH_CONFIG_PATH
    } else {
        $configPath = "${env:USERPROFILE}\.config\winfetch\config.ps1"
    }
}

# generate default config
if ($genconf -and (Test-Path $configPath)) {
    $choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "overwrite your configuration with the default"
    $choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "do nothing and exit"
    $result = $Host.UI.PromptForChoice("Resetting your config to default will overwrite it.",
        "Do you want to continue?", ($choiceYes, $choiceNo), 1)
    if ($result -eq 0) { Remove-Item -Path $configPath } else { exit 1 }
}

if (-not (Test-Path $configPath) -or [String]::IsNullOrWhiteSpace((Get-Content $configPath))) {
    New-Item -Type File -Path $configPath -Value $defaultConfig -Force | Out-Null
    if ($genconf) {
        Write-Host "Saved default config to '$configPath'."
        exit 0
    } else {
        Write-Host "Missing config: Saved default config to '$configPath'."
    }
}

# load config file
$config = . $configPath
if (-not $config -or $all) {
    $config = @(
        "title"
        "dashes"
        "os"
        "computer"
        "kernel"
        "motherboard"
        "uptime"
        "resolution"
        "ps_pkgs"
        "pkgs"
        "pwsh"
        "terminal"
        "theme"
        "cpu"
        "gpu"
        "cpu_usage"
        "memory"
        "disk"
        "battery"
        "locale"
        "timezone"
        "weather"
        "local_ip"
        "public_ip"
        "blank"
        "colorbar"
    )
}

# prevent config from overriding specified parameters
foreach ($param in $PSBoundParameters.Keys) {
    Set-Variable $param $PSBoundParameters[$param]
}

#endregion: Configuration

# ===== VARIABLES =====
#region: Variables
$e = [char]0x1B
$t = if ($blink) { "5" } else { "1" }
$script:ansiRegex = '([\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-ntqry=><~])))'
$cimSession = New-CimSession
$os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption, OSArchitecture, LastBootUpTime, TotalVisibleMemorySize, FreePhysicalMemory -CimSession $cimSession
$script:COLUMNS = $imgwidth

# ===== UPDATE PROCESS TYPE FOR 5.1 =====
# NOTE: Approx. 100ms added
if ($PSEdition -eq 'Desktop') {
    # .NET Core contains Parent and CommandLine properties, but not Desktop. This adds them, albeit more slowly, as it must query WMI for each process.
    # _CIMInstance property is first added to more quickly retrieve other properties
    Update-TypeData -MemberType ScriptProperty -MemberName _CIMInstance -TypeName 'System.Diagnostics.Process' -Value { try { Get-CimInstance -CimSession $cimSession -ClassName Win32_Process -Filter "ProcessId = '$($this.Id)'" } catch { $_ } } -Force
    # Add ParentProcessId pulled from Win32_Process
    Update-TypeData -MemberType ScriptProperty -MemberName ParentProcessId -TypeName 'System.Diagnostics.Process' -Value { try { ($this._CIMInstance).ParentProcessId } catch { $_ } } -Force
    # Finally, get the actual Process object for the Parent
    Update-TypeData -MemberType ScriptProperty -MemberName Parent -TypeName 'System.Diagnostics.Process' -Value { try { Get-Process -Id $this.ParentProcessId } catch { $_ } } -Force
    # Add CommandLine pulled from Win32_Process
    # Update-TypeData -MemberType ScriptProperty -MemberName CommandLine -TypeName 'System.Diagnostics.Process' -Value {try{($this._CIMInstance).CommandLine}catch{$_}} -Force
}
#endregion: Variables

# ===== UTILITY FUNCTIONS =====
#region: Utility Functions
function get_percent_bar {
    param ([Parameter(Mandatory)][int]$percent)

    if ($percent -gt 100) { $percent = 100 }
    elseif ($percent -lt 0) { $percent = 0 }

    $x = [char]9632
    $bar = $null

    $bar += "$e[97m[ $e[0m"
    for ($i = 1; $i -le ($barValue = ([math]::round($percent / 10))); $i++) {
        if ($i -le 6) { $bar += "$e[32m$x$e[0m" }
        elseif ($i -le 8) { $bar += "$e[93m$x$e[0m" }
        else { $bar += "$e[91m$x$e[0m" }
    }
    for ($i = 1; $i -le (10 - $barValue); $i++) { $bar += "$e[97m-$e[0m" }
    $bar += "$e[97m ]$e[0m"

    return $bar
}

function get_level_info {
    param (
        [string]$barprefix,
        [string]$style,
        [int]$percentage,
        [string]$text,
        [switch]$altstyle
    )

    switch ($style) {
        'bar' { return "$barprefix$(get_percent_bar $percentage)" }
        'textbar' { return "$text $(get_percent_bar $percentage)" }
        'bartext' { return "$barprefix$(get_percent_bar $percentage) $text" }
        default { if ($altstyle) { return "$percentage% ($text)" } else { return "$text ($percentage%)" } }
    }
}

function truncate_line {
    param (
        [string]$text,
        [int]$maxLength
    )
    $length = ($text -replace $ansiRegex).Length
    if ($length -le $maxLength) {
        return $text
    }
    $truncateAmt = $length - $maxLength
    $trucatedOutput = ""
    $parts = $text -split $ansiRegex

    for ($i = $parts.Length - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if (-not $part.StartsWith([char]27) -and $truncateAmt -gt 0) {
            $num = if ($truncateAmt -gt $part.Length) {
                $part.Length
            } else {
                $truncateAmt
            }
            $truncateAmt -= $num
            $part = $part.Substring(0, $part.Length - $num)
        }
        $trucatedOutput = "$part$trucatedOutput"
    }

    return $trucatedOutput
}

function write_output($lines, $time) {
    foreach ($line in $lines) {
        $output = "$e[1;33m$($line["title"])$e[0m"

        if ($line["title"] -and $line["content"]) {
            if ($timed) {
                $output = "$e[90m($e[37m{0:n3}$e[96ms$e[90m){1}: " -f $time.TotalSeconds, $output
            } else {
                $output += ": "
            }
        }

        $output += "$($line["content"])"

        if ($img) {
            if (-not $stripansi) {
                # move cursor to right of image
                $output = "$e[$(2 + $script:COLUMNS + $script:GAP)G$output"
            } else {
                # write image progressively
                $imgline = ("$($img[$script:writtenLines])" -replace $script:ansiRegex).PadRight($script:COLUMNS)
                $output = " $imgline   $output"
            }
        }

        $script:writtenLines++

        if ($stripansi) {
            $output = $output -replace $script:ansiRegex
            if ($output.Length -gt $script:freeSpace) {
                $output = $output.Substring(0, $output.Length - ($output.Length - $script:freeSpace))
            }
        } else {
            $output = truncate_line $output $script:freeSpace
        }

        Write-Output $output
    }
}
#endregion: Utility Functions

# ===== IMAGE =====
# TODO: Refactor
#region: Image
$img = if (-not $noimage -and -not $nooutput) {
    if ($image) {
        if ($image -eq 'wallpaper') {
            $image = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
        }

        Add-Type -AssemblyName 'System.Drawing'
        $OldImage = if (Test-Path $image -PathType Leaf) {
            [Drawing.Bitmap]::FromFile((Resolve-Path $image))
        } else {
            [Drawing.Bitmap]::FromStream((Invoke-WebRequest $image -UseBasicParsing).RawContentStream)
        }

        # Divide scaled height by 2.2 to compensate for ASCII characters being taller than they are wide
        [int]$ROWS = $OldImage.Height / $OldImage.Width * $COLUMNS / $(if ($ascii) { 2.2 } else { 1 })
        $Bitmap = New-Object System.Drawing.Bitmap @($OldImage, [Drawing.Size]"$COLUMNS,$ROWS")

        if ($ascii) {
            $chars = ' .,:;+iIH$@'
            for ($i = 0; $i -lt $Bitmap.Height; $i++) {
                $currline = ""
                for ($j = 0; $j -lt $Bitmap.Width; $j++) {
                    $p = $Bitmap.GetPixel($j, $i)
                    $currline += "$e[38;2;$($p.R);$($p.G);$($p.B)m$($chars[[math]::Floor($p.GetBrightness() * $chars.Length)])$e[0m"
                }
                $currline
            }
        } else {
            for ($i = 0; $i -lt $Bitmap.Height; $i += 2) {
                $currline = ""
                for ($j = 0; $j -lt $Bitmap.Width; $j++) {
                    $pixel1 = $Bitmap.GetPixel($j, $i)
                    $char = [char]0x2580
                    if ($i -ge $Bitmap.Height - 1) {
                        if ($pixel1.A -lt $alphathreshold) {
                            $char = [char]0x2800
                            $ansi = "$e[49m"
                        } else {
                            $ansi = "$e[38;2;$($pixel1.R);$($pixel1.G);$($pixel1.B)m"
                        }
                    } else {
                        $pixel2 = $Bitmap.GetPixel($j, $i + 1)
                        if ($pixel1.A -lt $alphathreshold -or $pixel2.A -lt $alphathreshold) {
                            if ($pixel1.A -lt $alphathreshold -and $pixel2.A -lt $alphathreshold) {
                                $char = [char]0x2800
                                $ansi = "$e[49m"
                            } elseif ($pixel1.A -lt $alphathreshold) {
                                $char = [char]0x2584
                                $ansi = "$e[49;38;2;$($pixel2.R);$($pixel2.G);$($pixel2.B)m"
                            } else {
                                $ansi = "$e[49;38;2;$($pixel1.R);$($pixel1.G);$($pixel1.B)m"
                            }
                        } else {
                            $ansi = "$e[38;2;$($pixel1.R);$($pixel1.G);$($pixel1.B);48;2;$($pixel2.R);$($pixel2.G);$($pixel2.B)m"
                        }
                    }
                    $currline += "$ansi$char$e[0m"
                }
                $currline
            }
        }

        $Bitmap.Dispose()
        $OldImage.Dispose()

    } elseif (($CustomAscii -is [Array]) -and ($CustomAscii.Length -gt 0)) {
        $CustomAscii
    } else {
        if (-not $logo) {
            if ($os -Like "*Windows 11 *") {
                $logo = "Windows 11"
            } elseif ($os -Like "*Windows 10 *" -Or $os -Like "*Windows 8.1 *" -Or $os -Like "*Windows 8 *") {
                $logo = "Windows 10"
            } else {
                $logo = "Windows 7"
            }
        }

        if ($logo -eq "Windows 11") {
            $COLUMNS = 32
            @(
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34m                                 "
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
            )
        } elseif ($logo -eq "Windows 10" -Or $logo -eq "Windows 8.1" -Or $logo -eq "Windows 8") {
            $COLUMNS = 34
            @(
                "${e}[${t};34m                    ....,,:;+ccllll"
                "${e}[${t};34m      ...,,+:;  cllllllllllllllllll"
                "${e}[${t};34m,cclllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34m                                   "
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34m``'ccllllllllll  lllllllllllllllllll"
                "${e}[${t};34m      ``' \\*::  :ccllllllllllllllll"
                "${e}[${t};34m                       ````````''*::cll"
                "${e}[${t};34m                                 ````"
            )
        } elseif ($logo -eq "Windows 7" -Or $logo -eq "Windows Vista" -Or $logo -eq "Windows XP") {
            $COLUMNS = 35
            @(
                "${e}[${t};31m        ,.=:!!t3Z3z.,               "
                "${e}[${t};31m       :tt:::tt333EE3               "
                "${e}[${t};31m       Et:::ztt33EEE  ${e}[32m@Ee.,      ..,"
                "${e}[${t};31m      ;tt:::tt333EE7 ${e}[32m;EEEEEEttttt33#"
                "${e}[${t};31m     :Et:::zt333EEQ. ${e}[32mSEEEEEttttt33QL"
                "${e}[${t};31m     it::::tt333EEF ${e}[32m@EEEEEEttttt33F "
                "${e}[${t};31m    ;3=*^``````'*4EEV ${e}[32m:EEEEEEttttt33@. "
                "${e}[${t};34m    ,.=::::it=., ${e}[31m`` ${e}[32m@EEEEEEtttz33QF  "
                "${e}[${t};34m   ;::::::::zt33)   ${e}[32m'4EEEtttji3P*   "
                "${e}[${t};34m  :t::::::::tt33 ${e}[33m:Z3z..  ${e}[32m```` ${e}[33m,..g.   "
                "${e}[${t};34m  i::::::::zt33F ${e}[33mAEEEtttt::::ztF    "
                "${e}[${t};34m ;:::::::::t33V ${e}[33m;EEEttttt::::t3     "
                "${e}[${t};34m E::::::::zt33L ${e}[33m@EEEtttt::::z3F     "
                "${e}[${t};34m{3=*^``````'*4E3) ${e}[33m;EEEtttt:::::tZ``     "
                "${e}[${t};34m            `` ${e}[33m:EEEEtttt::::z7       "
                "${e}[${t};33m                'VEzjt:;;z>*``       "
            )
        } elseif ($logo -eq "Microsoft") {
            $COLUMNS = 13
            @(
                "${e}[${t};31m┌─────┐${e}[32m┌─────┐"
                "${e}[${t};31m│     │${e}[32m│     │"
                "${e}[${t};31m│     │${e}[32m│     │"
                "${e}[${t};31m└─────┘${e}[32m└─────┘"
                "${e}[${t};34m┌─────┐${e}[33m┌─────┐"
                "${e}[${t};34m│     │${e}[33m│     │"
                "${e}[${t};34m│     │${e}[33m│     │"
                "${e}[${t};34m└─────┘${e}[33m└─────┘"
            )
        } elseif ($logo -eq "Windows 2000" -Or $logo -eq "Windows 98" -Or $logo -eq "Windows 95") {
            $COLUMNS = 45
            @(
                "                         ${e}[${t};30mdBBBBBBBb"
                "                     ${e}[${t};30mdBBBBBBBBBBBBBBBb"
                "             ${e}[${t};30m   000 BBBBBBBBBBBBBBBBBBBB"
                "${e}[${t};30m:::::        000000 BBBBB${e}[${t};31mdBB${e}[${t};30mBBBB${e}[${t};32mBBBb${e}[${t};30mBBBBBBB"
                "${e}[${t};31m::::: ${e}[${t};30m====== 000${e}[${t};31m000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== ${e}[${t};31m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== ${e}[${t};31m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== ${e}[${t};31m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== 000000 BBBBf${e}[${t};30mBBBBBBBBBBB${e}[${t};32m`BBBB${e}[${t};30mBBBB"
                "${e}[${t};30m::::: ${e}[${t};31m====== 000${e}[${t};30m000 BBBBBBBBBBBBBBBBBBBBBBBBB"
                "${e}[${t};30m::::: ====== 000000 BBBBB${e}[${t};34mdBB${e}[${t};30mBBBB${e}[${t};33mBBBb${e}[${t};30mBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ${e}[${t};30m====== 000${e}[${t};34m000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBf${e}[${t};30mBBBBBBBBBBB${e}[${t};33m`BBBB${e}[${t};30mBBBB"
                "${e}[${t};30m::::: ${e}[${t};34m====== 000${e}[${t};30m000 BBBBBf         `BBBBBBBBB"
                "${e}[${t};30m   :: ====== 000000 BBf                `BBBBB"
                "     ${c1}   ==  000000 B                     BBB"
            )
        } else {
            Write-Error 'The only version logos supported are Windows 11, Windows 10/8.1/8, Windows 7/Vista/XP, Windows 2000/98/95 and Microsoft.'
            exit 1
        }
    }
}
#endregion: Image

#region: Info Functions
# ===== BLANK =====
function info_blank {
    return @{}
}


# ===== COLORBAR =====
function info_colorbar {
    return @(
        @{
            title   = ""
            content = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}{0}[0m') -f $e, '   '
        },
        @{
            title   = ""
            content = ('{0}[0;100m{1}{0}[0;101m{1}{0}[0;102m{1}{0}[0;103m{1}{0}[0;104m{1}{0}[0;105m{1}{0}[0;106m{1}{0}[0;107m{1}{0}[0m') -f $e, '   '
        }
    )
}


# ===== OS =====
function info_os {
    return @{
        title   = "OS"
        content = "$($os.Caption.TrimStart('Microsoft ')) [$($os.OSArchitecture)]"
    }
}


# ===== MOTHERBOARD =====
function info_motherboard {
    $motherboard = Get-CimInstance Win32_BaseBoard -CimSession $cimSession -Property Manufacturer, Product
    return @{
        title   = "Motherboard"
        content = "{0} {1}" -f $motherboard.Manufacturer, $motherboard.Product
    }
}


# ===== TITLE =====
function info_title {
    return @{
        title   = ""
        content = "${e}[1;33m{0}${e}[0m@${e}[1;33m{1}${e}[0m" -f [System.Environment]::UserName, $env:COMPUTERNAME
    }
}


# ===== DASHES =====
function info_dashes([int]$width) {
    if($width) {
        $length = $width
    } else {
        $length = [System.Environment]::UserName.Length + $env:COMPUTERNAME.Length + 1
    }
    return @{
        title   = ""
        content = "-" * $length
    }
}


# ===== COMPUTER =====
function info_computer {
    $compsys = Get-CimInstance -ClassName Win32_ComputerSystem -Property Manufacturer, Model -CimSession $cimSession
    return @{
        title   = "Host"
        content = '{0} {1}' -f $compsys.Manufacturer, $compsys.Model
    }
}


# ===== KERNEL =====
function info_kernel {
    return @{
        title   = "Kernel"
        content = "$([System.Environment]::OSVersion.Version)"
    }
}


# ===== UPTIME =====
function info_uptime {
    @{
        title   = "Uptime"
        content = $(switch ([System.DateTime]::Now - $os.LastBootUpTime) {
            ({ $PSItem.Days -eq 1 }) { '1 day' }
            ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days) days" }
            ({ $PSItem.Hours -eq 1 }) { '1 hour' }
            ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours) hours" }
            ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
            ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes) minutes" }
            }) -join ' '
    }
}


# ===== RESOLUTION =====
function info_resolution {
    Add-Type -AssemblyName System.Windows.Forms
    $displays = foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        "$($monitor.Bounds.Size.Width)x$($monitor.Bounds.Size.Height)"
    }

    return @{
        title   = "Resolution"
        content = $displays -join ', '
    }
}


# ===== TERMINAL =====
# this section works by getting the parent processes of the current powershell instance.
function info_terminal {
    $programsparent = 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'sh', 'bash', 'fish', 'env', 'nu', 'elvish', 'csh', 'tcsh', 'python', 'xonsh'
    # Because the Parent scriptproperty was added, we don't care if we're on Desktop or Core.
    $parent = (Get-Process -Id $PID).Parent
    for () {
        if ($parent.ProcessName -in $programsparent) {
            $parent = (Get-Process -Id $parent.ID).Parent
            continue
        }
        break
    }

    $terminal = switch ($parent.ProcessName) {
        { $PSItem -in 'explorer', 'conhost' } { 'Windows Console' }
        'Console' { 'Console2/Z' }
        'ConEmuC64' { 'ConEmu' }
        'WindowsTerminal' { 'Windows Terminal' }
        'FluentTerminal.SystemTray' { 'Fluent Terminal' }
        'Code' { 'Visual Studio Code' }
        # %ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe
        # %ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\ServiceHub\Hosts\ServiceHub.Host.dotnet.x64\ServiceHub.Host.dotnet.x64.exe
        { $PSItem -in 'devenv', 'ServiceHub.Host.dotnet.x64' } {
            if ($parent.Path -like '*\Microsoft Visual Studio\2022*') {
                'Visual Studio 2022'
            } else {
                'Visual Studio'
            }
        }
        default { $PSItem }
    }

    if (-not $terminal) {
        $terminal = "$e[91m(Unknown)"
    }

    return @{
        title   = "Terminal"
        content = $terminal
    }
}


# ===== THEME =====
function info_theme {
    $themeinfo = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme, AppsUseLightTheme
    $themename = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes' -Name CurrentTheme).CurrentTheme.Split('\')[-1].Replace('.theme', '')
    $systheme = if ($themeinfo.SystemUsesLightTheme) { "Light" } else { "Dark" }
    $apptheme = if ($themeinfo.AppsUseLightTheme) { "Light" } else { "Dark" }
    return @{
        title   = "Theme"
        content = "$themename (System: $systheme, Apps: $apptheme)"
    }
}


# ===== CPU/GPU =====
function info_cpu {
    $cpu = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default').OpenSubKey("HARDWARE\DESCRIPTION\System\CentralProcessor\0")
    $cpuname = $cpu.GetValue("ProcessorNameString")
    $cpuname = if ($cpuname.Contains('@')) {
        ($cpuname -Split '@')[0].Trim()
    } else {
        $cpuname.Trim()
    }
    return @{
        title   = "CPU"
        content = "{0} @ {1:n2}GHz" -f $cpuname, ($cpu.GetValue("~MHz") / 1000) # the format method rounds without losing as much speed as calling the [math]::Round() method
        # [math]::Round($cpu.GetValue("~MHz") / 1000, 1) is 2-5ms slower
    }
}

function info_gpu {
    [System.Collections.ArrayList]$lines = @()
    #loop through Win32_VideoController
    foreach ($gpu in Get-CimInstance -ClassName Win32_VideoController -Property Name -CimSession $cimSession) {
        [void]$lines.Add(@{
                title   = "GPU"
                content = $gpu.Name
            })
    }
    return $lines
}


# ===== CPU USAGE =====
function info_cpu_usage {
    # Get all running processes and assign to a variable to allow reuse
    $processes = [System.Diagnostics.Process]::GetProcesses()
    $loadpercent = 0
    $proccount = $processes.Count
    # Get the number of logical processors in the system
    $CPUs = [System.Environment]::ProcessorCount

    $timenow = [System.Datetime]::Now
    $processes.ForEach{
        if ($_.StartTime -gt 0) {
            # Replicate the functionality of New-Timespan
            $timespan = ($timenow.Subtract($_.StartTime)).TotalSeconds

            # Calculate the CPU usage of the process and add to the total
            $loadpercent += $_.CPU * 100 / $timespan / $CPUs
        }
    }

    return @{
        title   = "CPU Usage"
        content = get_level_info "" $cpustyle $loadpercent "$proccount processes" -altstyle
    }
}


# ===== MEMORY =====
function info_memory {
    $total = $os.TotalVisibleMemorySize / 1mb
    $used = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1mb
    $usage = [math]::floor(($used / $total * 100))
    return @{
        title   = "Memory"
        content = get_level_info "   " $memorystyle $usage "$($used.ToString("#.##")) GiB / $($total.ToString("#.##")) GiB"
    }
}


# ===== DISK USAGE =====
function info_disk {
    [System.Collections.ArrayList]$lines = @()

    function to_units($value) {
        if ($value -gt 1tb) {
            return "$([math]::round($value / 1tb, 1)) TiB"
        } else {
            return "$([math]::floor($value / 1gb)) GiB"
        }
    }

    [System.IO.DriveInfo]::GetDrives().ForEach{
        $diskLetter = $_.Name.SubString(0, 2)

        if ($showDisks.Contains($diskLetter) -or $showDisks.Contains("*")) {
            try {
                if ($_.TotalSize -gt 0) {
                    $used = $_.TotalSize - $_.AvailableFreeSpace
                    $usage = [math]::Floor(($used / $_.TotalSize * 100))
    
                    [void]$lines.Add(@{
                            title   = "Disk ($diskLetter)"
                            content = get_level_info "" $diskstyle $usage "$(to_units $used) / $(to_units $_.TotalSize)"
                        })
                }
            } catch {
                [void]$lines.Add(@{
                        title   = "Disk ($diskLetter)"
                        content = "(failed to get disk usage)"
                    })
            }
        }
    }

    return $lines
}


# ===== POWERSHELL VERSION =====
function info_pwsh {
    return @{
        title   = "Shell"
        content = "PowerShell v$($PSVersionTable.PSVersion)"
    }
}


# ===== POWERSHELL PACKAGES =====
function info_ps_pkgs {
    $ps_pkgs = @()

    # Get all installed packages
    $pgp = Get-Package -ProviderName PowerShellGet
    # Get the number of packages where the tags contains PSModule or PSScript
    $modulecount = $pgp.Where({ $_.Metadata["tags"] -like "*PSModule*" }).count
    $scriptcount = $pgp.Where({ $_.Metadata["tags"] -like "*PSScript*" }).count

    if ($modulecount) {
        if ($modulecount -eq 1) { $modulestring = "1 Module" }
        else { $modulestring = "$modulecount Modules" }

        $ps_pkgs += "$modulestring"
    }

    if ($scriptcount) {
        if ($scriptcount -eq 1) { $scriptstring = "1 Script" }
        else { $scriptstring = "$scriptcount Scripts" }

        $ps_pkgs += "$scriptstring"
    }

    if (-not $ps_pkgs) {
        $ps_pkgs = "(none)"
    }

    return @{
        title   = "PS Packages"
        content = $ps_pkgs -join ', '
    }
}

# TODO: Improve winget speed and detection
# ===== PACKAGES =====
function info_pkgs {
    $pkgs = @()

    # TODO: look into https://learn.microsoft.com/en-us/windows/package-manager/winget/export
    if ("winget" -in $ShowPkgs -and (Get-Command -Name winget -ErrorAction Ignore)) {
        $wingetpkg = (winget list | Where-Object { $_.Trim("`n`r`t`b-\|/ ").Length -ne 0 } | Measure-Object).Count - 1

        if ($wingetpkg) {
            $pkgs += "$wingetpkg (system)"
        }
    }

    if ("choco" -in $ShowPkgs -and (Get-Command -Name choco -ErrorAction Ignore)) {
        $chocopkg = Invoke-Expression $(
            "(& choco list" + $(if ([version](& choco --version).Split('-')[0]`
                        -lt [version]'2.0.0') { " --local-only" }) + ")[-1].Split(' ')[0] - 1")

        if ($chocopkg) {
            $pkgs += "$chocopkg (choco)"
        }
    }

    if ("scoop" -in $ShowPkgs) {
        $scoopdir = if ($Env:SCOOP) { "$Env:SCOOP\apps" } else { "$Env:UserProfile\scoop\apps" }

        if (Test-Path $scoopdir) {
            $scooppkg = (Get-ChildItem -Path $scoopdir -Directory).Count - 1
        }

        if ($scooppkg) {
            $pkgs += "$scooppkg (scoop)"
        }
    }

    foreach ($pkgitem in $CustomPkgs) {
        if (Test-Path Function:"info_pkg_$pkgitem") {
            $count = & "info_pkg_$pkgitem"
            $pkgs += "$count ($pkgitem)"
        }
    }

    if (-not $pkgs) {
        $pkgs = "(none)"
    }

    return @{
        title   = "Packages"
        content = $pkgs -join ', '
    }
}


# ===== BATTERY =====
function info_battery {
    Add-Type -AssemblyName System.Windows.Forms
    $battery = [System.Windows.Forms.SystemInformation]::PowerStatus

    if ($battery.BatteryChargeStatus -eq 'NoSystemBattery') {
        return @{
            title   = "Battery"
            content = "(none)"
        }
    }

    $status = if ($battery.BatteryChargeStatus -like '*Charging*') {
        "Charging"
    } elseif ($battery.PowerLineStatus -like '*Online*') {
        "Plugged in"
    } else {
        "Discharging"
    }

    $timeRemaining = $battery.BatteryLifeRemaining / 60
    # Don't show time remaining if Windows hasn't properly reported it yet
    $timeFormatted = if ($timeRemaining -ge 0) {
        $hours = [math]::floor($timeRemaining / 60)
        $minutes = [math]::floor($timeRemaining % 60)
        ", ${hours}h ${minutes}m"
    }

    return @{
        title   = "Battery"
        content = get_level_info "  " $batterystyle "$([math]::round($battery.BatteryLifePercent * 100))" "$status$timeFormatted" -altstyle
    }
}


# ===== LOCALE =====
# Performance improvement is ~10ms over the large hashtable and registry lookup
function info_locale {
    $RegionInfo = [System.Globalization.RegionInfo]::CurrentRegion.DisplayName
    (Get-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile').Languages | ForEach-Object {
        # Retrieve the language name from CultureInfo
        $languagecode = $_
        try {
            # Cross-reference the language code with the CultureInfo DisplayName
            $languagename = [System.Globalization.CultureInfo]::GetCultureInfo($languagecode).DisplayName
            $Languages += " - $languagename"
        } catch {
            # if not found, just display the code
            $Languages += " - $languagecode"
        }
    }

    return @{
        title   = "Locale"
        content = "${RegionInfo}${Languages}"
    }
}

# ===== TIMEZONE =====
function info_timezone {
    # ID = Timezone
    # DisplayName = (UTC-/+xxx) Timezone (Region)
    $TimeZone = [System.TimeZoneInfo]::Local.DisplayName
    return @{
        title   = "Timezone"
        content = $TimeZone
    }
}

# ===== WEATHER =====
function info_weather {
    return @{
        title   = "Weather"
        content = try {
            (Invoke-RestMethod -TimeoutSec 5 wttr.in/?format="%t+-+%C+(%l)").TrimStart("+")
        } catch {
            "$e[91m(Network Error)"
        }
    }
}


# ===== IP =====
function info_local_ip {
    try {
        # Get all network adapters
        foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            # Get the IP information of each adapter
            $properties = $ni.GetIPProperties()
            # Check if the adapter is online, has a gateway address, and the adapter does not have a loopback address
            if ($ni.OperationalStatus -eq 'Up' -and !($null -eq $properties.GatewayAddresses[0]) -and !$properties.GatewayAddresses[0].Address.ToString().Equals("0.0.0.0")) {
                # Check if adapter is a WiFi or Ethernet adapter
                if ($ni.NetworkInterfaceType -eq "Wireless80211" -or $ni.NetworkInterfaceType -eq "Ethernet") {
                    foreach ($ip in $properties.UnicastAddresses) {
                        if ($ip.Address.AddressFamily -eq "InterNetwork") {
                            if (!$local_ip) { $local_ip = $ip.Address.ToString() }
                        }
                    }
                }
            }
        }
    } catch {
    }
    return @{
        title   = "Local IP"
        content = if (-not $local_ip) {
            "$e[91m(Unknown)"
        } else {
            $local_ip
        }
    }
}

function info_public_ip {
    return @{
        title   = "Public IP"
        content = try {
            Invoke-RestMethod -TimeoutSec 5 ifconfig.me/ip
        } catch {
            "$e[91m(Network Error)"
        }
    }
}
#endregion: Functions

$timeoverhead = $sw1.Elapsed
$timetotal = [timespan]::Zero

function script:OutputInfo {
    Param(
        $InfoOutput
    )
    
    # write info
    foreach ($line in $InfoOutput) {
        $output = "$e[1;33m$($line["title"])$e[0m"

        if ($line["title"] -and $line["content"]) {
            if ($timed) {
                $output = "$e[90m($e[37m{0:n3}$e[96ms$e[90m){1}: " -f $infotime.TotalSeconds, $output
            } else {
                $output += ": "
            }
        }

        $output += "$($line["content"])"

        if ($img) {
            if (-not $stripansi) {
                # move cursor to right of image
                $output = "$e[$(2 + $COLUMNS + $GAP)G$output"
            } else {
                # write image progressively
                $imgline = ("$($img[$writtenLines])" -replace $ansiRegex).PadRight($COLUMNS)
                $output = " $imgline   $output"
            }
        }

        $writtenLines++

        if ($stripansi) {
            $output = $output -replace $ansiRegex
            if ($output.Length -gt $freeSpace) {
                $output = $output.Substring(0, $output.Length - ($output.Length - $freeSpace))
            }
        } else {
            $output = truncate_line $output $freeSpace
        }

        Write-Output $output
    }
    
    if ($stripansi) {
        # write out remaining image lines
        for ($i = $writtenLines; $i -lt $img.Length; $i++) {
            $imgline = ("$($img[$i])" -replace $ansiRegex).PadRight($COLUMNS)
            Write-Output " $imgline"
        }
        # move cursor back to the bottom and print 2 newlines
        Write-Output "`n"
    } else {
        $diff = $img.Length - $writtenLines
        if ($img -and $diff -gt 0) {
            Write-Output "$e[${diff}B"
        } else {
            Write-Output ""
        }
        Write-Output "$e[?25h"
    }   
}

#region: Main
if(!$nooutput) {
    if ($stripansi) {
        Write-Output ""
    } else {
        # unhide the cursor after a terminating error
        trap { "$e[?25h"; break }
    
        # reset terminal sequences and display a newline
        Write-Output "$e[0m$e[?25l"
        
        # write logo
        foreach ($line in $img) {
            Write-Output " $line"
        }
    }
    
    $script:GAP = 3
    $script:writtenLines = 0
    $script:freeSpace = $Host.UI.RawUI.WindowSize.Width - 1
    
    # move cursor to top of image and to its right
    # see: https://espterm.github.io/docs/VT100%20escape%20codes.html
    # TODO: ^[D to move/scroll window up one line * ($img.Length - [Console]::WindowHeight)
    # [console]::MoveBufferArea(0, 0, $COLUMNS, $img.Length, 0, 1) # Scroll image up
    <# int sourceLeft, # leftmost column of source area
        int sourceTop, # topmost row of source area
        int sourceWidth, # number of columns in source area
        int sourceHeight, # number of rows in source area
        int targetLeft, # leftmost column of the destination
        int targetTop # topmost row of the column)
    #>
    if ($img -and -not $stripansi) {
        # Columns = image width + 1
        <#
        $img $GAP Info(Title: Content)
        $img $GAP Info(Title: Content)
        $img $GAP Info(Title: Content)
        #>
        $freeSpace -= 1 + $COLUMNS + $GAP
        Write-Output "$e[$($img.Length + 1)A" # Move cursor up N lines
    }

    $configoutput = @()
    
    # BUG: script functions are not recognized in Job scriptblocks unless the definition is passed in ArgumentList or InitializationScript
    if ($parallel) {
        # create thread jobs for each function
        $jobs = @()
        foreach ($item in $config) {
            $FuncName = "info_$item"
            if(Test-Path Function:$FuncName) {
                $splat = @{
                    Name          = "winfetch-$item"
                    ScriptBlock   = {
                        Param($Func, $PkgFuncs)

                        if($PkgFuncs) {
                            foreach ($PkgFunc in $PkgFuncs) {
                                Invoke-Expression $PkgFunc
                            }
                        }

                        Invoke-Expression $Func
                    }
                    ArgumentList  = (Get-Command $FuncName).Definition
                    # ThrottleLimit = 5
                }
                # Load custom package functions to pass to job
                if($item -eq "pkgs") {
                    $CustomPkgDefs = @()
                    foreach ($pkgitem in $CustomPkgs) {
                        if (Test-Path Function:"info_pkg_$pkgitem") {
                            $CustomPkgDefs += (gcm "info_pkg_$pkgitem").Definition
                        }
                    }
                    $splat.ArgumentList += $CustomPkgDefs
                }
            } else {
                $splat = @{
                    Name          = "winfetch-$item"
                    ScriptBlock   = { Return @{title = "$([char]0x1B)[31mfunction '$using:FuncName' not found"} }
                }
            }
            # $ThreadJob = Start-ThreadJob @splat
            $jobs += Start-Job -Name "winfetch-$item" -ArgumentList (gcm "info_$item").Definition -ScriptBlock {Param($fdef) iex $fdef }
            # $jobs = Start-Job @splat
        }
            
        # Wait for all jobs to complete
        $jobs | Wait-Job | Out-Null
    
        # Process each job result
        foreach ($job in $jobs) {
            $infotime = $job.PSEndTime - $job.PSBeginTime
            $timetotal += $infotime
            $info = $job | Receive-Job
        
            if ($info) {
                $configoutput += $info
            } else {
                continue
            }
        
            write_output -lines $info -time $infotime
        }
    } else {
        foreach($item in $config) {
            if (Test-Path Function:"info_$item") {
                if ($timed) {
                    if($fitdashes -and $item -eq 'dashes' -and $lastwidth -gt 0) {
                        # fit dashes to last item's length
                        $infotime = Measure-Command { $info = & "info_$item" $lastwidth }
                    } else {
                        $infotime = Measure-Command { $info = & "info_$item" }
                    }
                    $timetotal += $infotime
                } else {
                    if($fitdashes -and $item -eq 'dashes' -and $lastwidth -gt 0) {
                        # fit dashes to last item's length
                        $info = & "info_$item" $lastwidth
                    } else {
                        $info = & "info_$item"
                    }
                }
            } else {
                $info = @{ title = "$e[31mfunction 'info_$item' not found" }
            }
            
            if (-not $info) {
                continue
            } else {
                # measure the length of the title and content
                $lastwidth = ($info.title -replace $script:ansiRegex).Length
                if($info.ContainsKey('content')) {
                    $lastwidth += ($info.Content -replace $script:ansiRegex).Length + 2
                }
            }
        
            # this doesn't need to be cast as an array for foreach to work on a single object
            <# if ($info -isnot [array]) {
                $info = @($info)
            } #>
            
            $configoutput += $info
        }
    }
    script:OutputInfo -ConfigLines $configoutput
}

if ($timed -and !$nooutput) {
    "$e[1;33mOverhead$e[0m:   {0:n3}" -f $timeoverhead.TotalSeconds
    "$e[1;33mFunctions$e[0m:  {0:n3}" -f $timetotal.TotalSeconds
    "$e[1;33mFunc Avg$e[0m:   {0:n3}" -f ($timetotal.TotalSeconds / $writtenLines)
    "$e[1;33mTotal time$e[0m: {0:n3}" -f $sw1.Elapsed.TotalSeconds
}

$sw1.Stop()
$cimSession | Remove-CimSession
#endregion: Main

#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|
#