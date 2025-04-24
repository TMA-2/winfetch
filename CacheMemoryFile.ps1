# Uses MemoryCache class, and writes to persistent Json file
# TODO: Test!

using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Runtime.Caching
using namespace System.Collections.Generic

class CacheMemoryFile {
    #region: properties
    static [MemoryCache] $MemoryCache = [MemoryCache]::Default
    # this is the default Winfetch configuration directory that contains config.ps1
    static [string] $CacheDirectory = "$env:USERPROFILE\.config\winfetch"
    static [string] $CacheFileName = 'Cache.json'
    static [string] $CachePath = "$env:userprofile\.config\winfetch\Cache.json"
    static [int] $CacheMaxAge = 900
    #endregion: properties

    #region: ctor
    CacheMemoryFile() {}

    CacheMemoryFile([int] $MaxAgeInSeconds) {
        [CacheMemoryFile]::CacheMaxAge = $MaxAgeInSeconds
    }

    CacheMemoryFile([string] $CachePath) {
        $File = [Path]::GetFileName($CachePath)
        $Directory = [Path]::GetDirectoryName($CachePath)
        $this.CombinePath($Directory, $File)
    }

    CacheMemoryFile([string] $CachePath, [int] $MaxAgeInSeconds) {
        $File = [Path]::GetFileName($CachePath)
        $Directory = [Path]::GetDirectoryName($CachePath)
        $this.CombinePath($Directory, $File)
        [CacheMemoryFile]::CacheMaxAge = $MaxAgeInSeconds
    }
    #endregion: ctor

    #region: methods
    hidden [void] CombinePath([string]$Directory, [string]$File) {
        [CacheMemoryFile]::CacheDirectory = $Directory
        [CacheMemoryFile]::CacheFileName = $File
        [CacheMemoryFile]::CachePath = [Path]::Combine([CacheMemoryFile]::CacheDirectory, [CacheMemoryFile]::CacheFileName)
    }

    [bool] IsCacheValid([string] $Key) {
        # Check if the cache item exists and is valid
        $CacheItem = [CacheMemoryFile]::MemoryCache.GetCacheItem($Key)
        if ($null -ne $CacheItem) {
            return $true
        }
        return $false
    }

    [void] SaveToCache([string] $Key, [object] $Data) {
        # Create a cache policy with expiration
        $CachePolicy = [CacheItemPolicy]::new()
        $CachePolicy.AbsoluteExpiration = (Get-Date).AddSeconds([CacheMemoryFile]::CacheMaxAge)

        # Add the data to the memory cache
        [CacheMemoryFile]::MemoryCache.Set($Key, $Data, $CachePolicy)

        # Save to file for persistence
        if (!(Test-Path ([CacheMemoryFile]::CacheDirectory))) {
            New-Item -ItemType Directory -Path ([CacheMemoryFile]::CacheDirectory) | Out-Null
        }
        $CacheData = @{
            DateTime = (Get-Date).ToString("s")
            MaxAge = [CacheMemoryFile]::CacheMaxAge
            Cache = @{
                $Key = @{
                    content = $Data
                    LastWriteTime = (Get-Date).ToString("s")
                }
            }
        }
        $CacheData | ConvertTo-Json -Depth 10 | Set-Content -Path ([CacheMemoryFile]::CachePath)
    }

    [object] LoadFromCache([string] $Key) {
        # Retrieve the data from the memory cache
        $CacheItem = [CacheMemoryFile]::MemoryCache.GetCacheItem($Key)
        if ($null -ne $CacheItem) {
            return $CacheItem.Value
        }
        return $null
    }

    [object] GetOrExecute([string] $Key, [scriptblock] $Command) {
        if ([CacheMemoryFile]::IsCacheValid($Key)) {
            return [CacheMemoryFile]::LoadFromCache($Key)
        } else {
            $Result = & $Command
            [CacheMemoryFile]::SaveToCache($Key, $Result)
            return $Result
        }
    }
    #endregion: methods
}

# Example usage:
function _TestCache {
    function info_test {
        return @{
            Title = "Function Title"
            Content = "Value from $($MyInvocation.MyCommand.Name)"
        }
    }

    $cache = [CacheMemoryFile]::new("$env:TEMP\winfetch\cache.json", 300)
    $result = $cache.GetOrExecute("Get-Process", { Get-Process })
    $result | Format-Table
}