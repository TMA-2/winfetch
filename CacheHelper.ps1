using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic

# cache in memory
class CacheHelper
{
    static [Dictionary[string, string]] $ObjectCache = [Dictionary[string, string]]::new()

    static [bool] $IsCacheEnabled = $true

    # Validates that the string is a valid PowerShell command with no nested expressions
    hidden static [bool] CommandIsSafe([string] $Command) {
        $ParsedTokens = $null
        $Errors = $null
        $null = [Parser]::ParseInput($Command, [ref]$ParsedTokens, [ref]$Errors)
        if ($Errors.Count -gt 0) {
            return $false
        }
        foreach ($Token in $ParsedTokens) {
            if
            (
                $Token -isnot [StringLiteralToken] -and
                $Token -isnot [ParameterToken] -and
                $Token.Kind -ne [TokenKind]::EndOfInput -and
                $Token.Kind -ne [TokenKind]::Identifier
            ) {
                return $false
            }
        }
        return $true
    }

    static [Object[]] GetCachedResults([string] $Command, [bool] $ValidateInput)
    {
        $Result = $null
        if ([CacheHelper]::ObjectCache.TryGetValue($Command, [ref] $Result))
        {
            return $Result
        }
        $Result = if (!$ValidateInput -or [CacheHelper]::CommandIsSafe($Command))
        {
            try
            {
                Invoke-Expression -Command $Command
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
        $this.CacheFileName = $CacheFileName
        $this.CachePath = [IO.Path]::Combine($this.CacheDirectory, $this.CacheFileName)
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

    [object]LoadFromCache() {
        return Get-Content -Path $this.CachePath -Raw | ConvertFrom-Json
    }

    [object]GetOrExecute([scriptblock]$ScriptBlock) {
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