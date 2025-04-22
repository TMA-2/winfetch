using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Runtime.Caching
using namespace System.Collections.Generic

class CacheOutput {
    static [MemoryCache] $MemoryCache = [MemoryCache]::Default
    static [string] $CacheDirectory = "$env:userprofile\.config\winfetch"
    static [string] $CacheFileName = 'Cache.json'
    static [string] $CachePath = [IO.Path]::Combine([CacheOutput]::CacheDirectory, [CacheOutput]::CacheFileName)
    static [int] $CacheMaxAge = 900

    #region: ctor
    CacheOutput() {}

    CacheOutput([string] $CacheFileName, [int] $MaxAgeInSeconds) {
        [CacheOutput]::CacheFileName = $CacheFileName
        [CacheOutput]::CachePath = [IO.Path]::Combine([CacheOutput]::CacheDirectory, [CacheOutput]::CacheFileName)
        [CacheOutput]::CacheMaxAge = $MaxAgeInSeconds
    }
    #endregion: ctor

    #region: methods
    [bool] IsCacheValid([string] $Key) {
        # Check if the cache item exists and is valid
        $CacheItem = [CacheOutput]::MemoryCache.GetCacheItem($Key)
        if ($CacheItem -ne $null) {
            return $true
        }
        return $false
    }

    [void] SaveToCache([string] $Key, [object] $Data) {
        # Create a cache policy with expiration
        $CachePolicy = [CacheItemPolicy]::new()
        $CachePolicy.AbsoluteExpiration = (Get-Date).AddSeconds([CacheOutput]::CacheMaxAge)

        # Add the data to the memory cache
        [CacheOutput]::MemoryCache.Set($Key, $Data, $CachePolicy)

        # Save to file for persistence
        if (!(Test-Path ([CacheOutput]::CacheDirectory))) {
            New-Item -ItemType Directory -Path ([CacheOutput]::CacheDirectory) | Out-Null
        }
        $CacheData = @{
            DateTime = (Get-Date).ToString("s")
            MaxAge = [CacheOutput]::CacheMaxAge
            Cache = @{
                $Key = @{
                    content = $Data
                    LastWriteTime = (Get-Date).ToString("s")
                }
            }
        }
        $CacheData | ConvertTo-Json -Depth 10 | Set-Content -Path ([CacheOutput]::CachePath)
    }

    [object] LoadFromCache([string] $Key) {
        # Retrieve the data from the memory cache
        $CacheItem = [CacheOutput]::MemoryCache.GetCacheItem($Key)
        if ($CacheItem -ne $null) {
            return $CacheItem.Value
        }
        return $null
    }

    [object] GetOrExecute([string] $Key, [scriptblock] $Command) {
        if ([CacheOutput]::IsCacheValid($Key)) {
            return [CacheOutput]::LoadFromCache($Key)
        } else {
            $Result = & $Command
            [CacheOutput]::SaveToCache($Key, $Result)
            return $Result
        }
    }
    #endregion: methods
}

# Example usage:
# $cache = [CacheOutput]::new("Cache.json", 3600)
# $result = $cache.GetOrExecute("Get-Process", { Get-Process })
# $result | Format-Table