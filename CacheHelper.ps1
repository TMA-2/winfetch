using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Runtime.Caching
using namespace System.Collections.Generic

# investigate using https://learn.microsoft.com/en-us/dotnet/api/system.runtime.caching.cacheitem?view=netframework-4.8.1

# cache in memory
class CacheMemory
{
    static [MemoryCache]$MemoryCache = [MemoryCache]::new("WinfetchCache")
    static [bool] $IsCacheEnabled = $true

    # Validates that the string is a valid info_* function with no nested expressions
    hidden static [bool] CommandIsSafe([string] $Command) {
        $ParsedTokens = $null
        $Errors = $null
        $null = [Parser]::ParseInput($Command, [ref]$ParsedTokens, [ref]$Errors)
        if ($Errors.Count -gt 0) {
            return $false
        }
        foreach ($Token in $ParsedTokens) {
            $Unsafe = $Token -isnot [StringLiteralToken] -and `
                $Token -isnot [ParameterToken] -and `
                $Token.Kind -ne [TokenKind]::EndOfInput -and `
                $Token.Kind -ne [TokenKind]::Identifier
            if($Unsafe) {return $false}
        }
        # Check that the function name is expected and exists
        $CommandName = $ParsedTokens.Where({$_.TokenFlags -eq [TokenFlags]::CommandName}).Text
        if($CommandName -match '^info_\w+' -and (gcm $CommandName -ea SilentlyContinue)) {
            return $true
        } else {
            return $false
        }
    }

    static [hashtable] GetCachedResults([string] $Command, [bool] $ValidateInput, [int] $CacheDurationInSeconds = 900)
    {
        # Value exists in cache
        $CacheItem = [CacheMemory]::MemoryCache.GetCacheItem($Command)
        if ($null -ne $CacheItem) {
            return $CacheItem.Value
        }

        $Result = if (!$ValidateInput -or [CacheMemory]::CommandIsSafe($Command))
        {
            try {
                & $Command
            }
            catch {
                return $null
            }
        }
        else {
            return $null
        }

        if($null -ne $Result) {
            $CachePolicy = [CacheItemPolicy]::new()
            $CachePolicy.AbsoluteExpiration = [DateTimeOffset]::Now.AddSeconds($CacheDurationInSeconds)
            [CacheMemory]::MemoryCache.Add($Command, $Result, $CachePolicy)
        }

        return $Result
    }
}
class CacheHelper
{
    static [Dictionary[string, hashtable]] $ObjectCache = [Dictionary[string, hashtable]]::new()
    
    static [bool] $IsCacheEnabled = $true

    # Validates that the string is a valid info_* function with no nested expressions
    hidden static [bool] CommandIsSafe([string] $Command) {
        $ParsedTokens = $null
        $Errors = $null
        $null = [Parser]::ParseInput($Command, [ref]$ParsedTokens, [ref]$Errors)
        if ($Errors.Count -gt 0) {
            return $false
        }
        foreach ($Token in $ParsedTokens) {
            $Unsafe = $Token -isnot [StringLiteralToken] -and `
                $Token -isnot [ParameterToken] -and `
                $Token.Kind -ne [TokenKind]::EndOfInput -and `
                $Token.Kind -ne [TokenKind]::Identifier
            if($Unsafe) {return $false}
        }
        # Check that the function name is expected and exists
        $CommandName = $ParsedTokens.Where({$_.TokenFlags -eq [TokenFlags]::CommandName}).Text
        if($CommandName -match '^info_\w+' -and (gcm $CommandName -ea SilentlyContinue)) {
            return $true
        } else {
            return $false
        }
    }

    static [hashtable] GetCachedResults([string] $Command, [bool] $ValidateInput)
    {
        # Value exists in cache
        $Result = $null
        if ([CacheHelper]::ObjectCache.TryGetValue($Command, [ref] $Result))
        {
            return $Result
        }
        $Result = if (!$ValidateInput -or [CacheHelper]::CommandIsSafe($Command))
        {
            try
            {
                # Invoke-Expression -Command $Command
                # Invoke-Command -ScriptBlock {& $Command}
                # [scriptblock]::Create($Command).InvokeReturnAsIs()
                & $Command
            }
            catch
            {
                return $null
            }
        }
        else
        {
            return $null
        }
        [CacheHelper]::ObjectCache.Add($Command, $Result)
        return $Result
    }
}

# cache to file
# JSON outline:
<#
{
        "DateTime": "2023-10-01T12:00:00Z",
        "MaxAge": 900,
        "Cache": {
            "Command1": {
                "content": "output",
                "LastWriteTime": "2023-10-01T12:00:00Z"
            },
            "Command2": {
                "content": "output",
                "LastWriteTime": "2023-10-01T12:00:00Z"
            }
        }
}
#>
class OutputCache {
    [string]$CacheDirectory = "$env:userprofile\.config\winfetch"
    [string]$CacheFileName = 'Cache.json'
    [string]$CachePath = [IO.Path]::Combine($this.CacheDirectory, $this.CacheFileName)
    [int]$CacheMaxAge = 900

    # Dictionary to store cached objects in memory
    static [Dictionary[string, String[]]]$ObjectCache = [Dictionary[string, String[]]]::new()

    [PSCustomObject]$CacheData = [PSCustomObject]@{
        DateTime = [datetime]::Now.ToString("s")
        MaxAge = $this.CacheMaxAge
        Cache = [PSCustomObject]@{}
    }

    #region: ctor
    OutputCache() {}

    OutputCache([string]$CacheFileName) {
        [OutputCache]::CacheFileName = $CacheFileName
        [OutputCache]::CachePath = [IO.Path]::Combine([OutputCache]::CacheDirectory, [OutputCache]::CacheFileName)
    }

    OutputCache([string]$CacheFileName, [int]$MaxAgeInSeconds) {
        $this.CacheFileName = $CacheFileName
        $this.CacheMaxAge = $MaxAgeInSeconds
        $this.CachePath = [IO.Path]::Combine($this.CacheDirectory, $this.CacheFileName)
    }
    #endregion: ctor

    #region: methods
    [bool]IsCacheValid() {
        if ([IO.Path]::Exists($this.CachePath)) {
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
        if ([OutputCache]::ObjectCache.ContainsKey($Key)) {
            [OutputCache]::ObjectCache[$Key] = $Data.ToString()
        } else {
            [OutputCache]::ObjectCache.Add($Key, $Data.ToString())
        }
        $Data = Get-Content $this.CachePath -Raw | ConvertFrom-Json
        $Data.Cache.$Key = [PSCustomObject]@{
            content = $Data
            LastWriteTime = [datetime]::Now.ToString("s")
        }
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $this.CachePath
    }

    [hashtable] LoadFromCache() {
        $Data = Get-Content -Path ([OutputCache]::CachePath) -Raw | ConvertFrom-Json
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
# $cache = [OutputCache]::new("c:\path\to\cache.json", 3600)
# $result = $cache.GetOrExecute({ Get-Process })