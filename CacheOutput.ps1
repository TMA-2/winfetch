using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Runtime.Caching
using namespace System.Collections.Generic

# cache to file
# JSON outline:
<#
{
    "DateTime": "2023-10-01T12:00:00Z",
    "MaxAge": 900,
    "Cache": {
        "info_abc": {
            "content": "output",
            "LastWriteTime": "2023-10-01T12:00:00Z"
        },
        "info_def": {
            "content": "output",
            "LastWriteTime": "2023-10-01T08:00:00Z"
        }
    }
}
#>
# investigate using https://learn.microsoft.com/en-us/dotnet/api/system.runtime.caching.cacheitem?view=netframework-4.8.1
class CacheOutput {
    static [string]$CacheDirectory = "$env:userprofile\.config\winfetch"
    static [string]$CacheFileName = 'Cache.json'
    static [string]$CachePath = [IO.Path]::Combine([CacheOutput]::CacheDirectory, [CacheOutput]::CacheFileName)
    static [int]$CacheMaxAge = 900

    # Dictionary to store cached objects in memory
    static [Dictionary[string, hashtable]]$ObjectCache = [Dictionary[string, hashtable]]::new()

    [PSCustomObject]$CacheData = [PSCustomObject]@{
        DateTime = [datetime]::Now.ToString("s")
        MaxAge = [cacheoutput]::CacheMaxAge
        Cache = [PSCustomObject]@{}
    }

    #region: ctor
    CacheOutput() {}

    CacheOutput([string]$CacheFileName) {
        [CacheOutput]::CacheFileName = $CacheFileName
        [CacheOutput]::CachePath = [IO.Path]::Combine([CacheOutput]::CacheDirectory, [CacheOutput]::CacheFileName)
    }

    CacheOutput([string]$CacheFileName, [int]$MaxAgeInSeconds) {
        [CacheOutput]::CacheFileName = $CacheFileName
        [CacheOutput]::CacheMaxAge = $MaxAgeInSeconds
        [CacheOutput]::CachePath = [IO.Path]::Combine([CacheOutput]::CacheDirectory, [CacheOutput]::CacheFileName)
    }
    #endregion: ctor

    #region: methods
    [bool]IsCacheValid() {
        if (Test-Path $this.CachePath) {
            $Data = Get-Content -Path $this.CachePath -Raw | ConvertFrom-Json
            $fileAge = [datetime]::Now - [datetime]$Data.DateTime
            if($fileAge.TotalSeconds -lt $this.CacheDurationInSeconds) {
                return $true
            } else {
                return $false
            }
        } else {
            return $false
        }
    }

    [void]SaveToCache([string]$Key, [object]$Data) {
        # save to in-memory cache
        if ([CacheOutput]::ObjectCache.ContainsKey($Key)) {
            [CacheOutput]::ObjectCache[$Key] = $Data.ToString()
        } else {
            [CacheOutput]::ObjectCache.Add($Key, $Data.ToString())
        }
        $Data = Get-Content [CacheOutput]::CachePath -Raw | ConvertFrom-Json
        $Data.Cache.$Key = [PSCustomObject]@{
            content = $Data
            LastWriteTime = [datetime]::Now.ToString("s")
        }
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $this.CachePath
    }

    [hashtable] LoadFromCache() {
        $Data = Get-Content -Path ([CacheOutput]::CachePath) -Raw | ConvertFrom-Json
        Return $Data
    }

    [object] GetOrExecute([scriptblock]$ScriptBlock) {
        if ($this.IsCacheValid()) {
            return $this.LoadFromCache()
        } else {
            $result = & $ScriptBlock
            $this.SaveToCache($result)
            return $result
        }
    }
    #endregion: methods
}

# Example usage:
# $cache = [CacheOutput]::new("c:\path\to\cache.json", 3600)
# $result = $cache.GetOrExecute({ Get-Process })