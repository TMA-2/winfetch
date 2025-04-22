class CacheManager {
    [string]$CacheFilePath = "$env:userprofile\.config\winfetch\Data.json"
    [int]$MaxAgeInSeconds = 900
    [pscustomobject]$Data

    CacheManager() {
        $this.Initialize()
    }

    CacheManager([int]$maxAgeInSeconds) {
        $this.MaxAgeInSeconds = $maxAgeInSeconds
        $this.Initialize()
    }

    CacheManager([string]$cacheFilePath, [int]$maxAgeInSeconds) {
        $this.CacheFilePath = $cacheFilePath
        $this.MaxAgeInSeconds = $maxAgeInSeconds
        $this.Initialize()
    }

    static [CacheManager] Default () {
        return [CacheManager]::new("$env:userprofile\.config\winfetch\Data.json", 300)
    }

    hidden [void] Initialize() {
        if (Test-Path $this.CacheFilePath) {
            $this.Data = Get-Content $this.CacheFilePath | ConvertFrom-Json
        } else {
            $this.Data = [pscustomobject]@{ }
        }
    }

    [void] WriteItem([string]$functionName, [hashtable]$data) {
        $this.Data | Add-Member -MemberType NoteProperty -Name $functionName -Value [pscustomobject]@{
            Title = $functionName
            Content = $data -as [pscustomobject]
            Timestamp = (Get-Date).ToString("s")
        }
        $this.SaveCacheToFile()
    }

    [pscustomobject] ReadItem([string]$functionName) {
        if ($this.Data.$functionName) {
            $item = $this.Data.$functionName
            $age = (Get-Date) - [datetime]$item.Timestamp
            # retrieve item if it is still valid
            if ($age.TotalSeconds -le $this.MaxAgeInSeconds) {
                return $item.Content
            }
            # refresh item otherwise
            else{
                $this.Data.psobject.Properties.Remove($functionName)
                $this.SaveCacheToFile()
                $output = & $functionName
                $this.WriteItem($functionName, $output)
                return $output
            }
        }
        return $null
    }

    [void] SaveCacheToFile() {
        <# $this.Data.Cache | ForEach-Object {
            $_.Timestamp = $_.Timestamp.ToString("s")
        } #>
        $this.Data | ConvertTo-Json -Depth 10 | Set-Content -Path $this.CacheFilePath
    }
}

function info_test {
    return @{
        Title = "Function Title";
        Content = "Value from $($MyInvocation.MyCommand.Name)"
    }
}

# Example usage:
$cache = [CacheManager]::new("~\.config\winfetch\cachetest.json", 300)

# Initialize the cache
[CacheManager]::Default()
$cache.Initialize()

$cache.WriteItem("MyFunction", @{ Key = "Value" })
$data = $cache.ReadItem("MyFunction")