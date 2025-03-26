$LocaleInfo = Import-PowerShellDataFile "$PSScriptRoot\LocaleLookup.psd1" -SkipLimitCheck

function info_locale1 {
    $localeLookup = $LocaleInfo.Locale
    $languageLookup = $LocaleInfo.Language
    
    # Get the current user's language and region using the registry
    $Region = $localeLookup[(Get-ItemProperty -Path 'HKCU:Control Panel\International\Geo').Nation]
    # Iterate through registry key in case multiple languages are configured
    (Get-ItemProperty -Path 'HKCU:Control Panel\International\User Profile').Languages | ForEach-Object {
        $Languages += " - $($languageLookup[$_])"
    }

    return @{
        title   = 'Locale'
        content = "$Region$Languages"
    }
}

function info_locale2 {
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

$TimeTotals = @()
1..10 | ForEach-Object {
    $Time1 = Measure-Command -Expression {$locale1 = info_locale1}
    $Time2 = Measure-Command -Expression {$locale2 = info_locale2}

    $TimeTotals += [PSCustomObject]@{
        Method1 = $Time1.TotalMilliseconds
        Method2 = $Time2.TotalMilliseconds
    }

    # Compare the outputs
    if ($locale1.content -eq $locale2.content) {
        Write-Host "Test ${_}: OK. Method 1: $($Time1.TotalMilliseconds)ms, Method 2: $($Time2.TotalMilliseconds)ms"
    } else {
        Write-Host "Test ${_}: Mismatch"
        Write-Host "Locale 1: $($locale1.content)"
        Write-Host "Locale 2: $($locale2.content)"
        Break
    }
}

$AverageTime1 = $TimeTotals | Measure-Object -Property Method1 -Average | Select-Object -ExpandProperty Average
$AverageTime2 = $TimeTotals | Measure-Object -Property Method2 -Average | Select-Object -ExpandProperty Average
Write-Host "Average Time: Method 1 = $([math]::Round($AverageTime1, 3))ms"
Write-Host "Average Time: Method 2 = $([math]::Round($AverageTime2, 3))ms"