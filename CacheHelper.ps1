using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic

# cache in memory
class CacheHelper
{
    static [Dictionary[string, Object[]]] $ObjectCache = [Dictionary[string, Object[]]]::new()
    
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
class OutputCache {
    [string]$CacheDirectory = "$env:userprofile\.config\winfetch"
    [string]$CacheFileName = 'Cache.json'
    [string]$CachePath = [IO.Path]::Combine($this.CacheDirectory, $this.CacheFileName)
    [int]$CacheDurationInSeconds = 900

    OutputCache() {}

    OutputCache([string]$CacheFileName) {
        $this.CacheFileName = $CacheFileName
        $this.CachePath = [IO.Path]::Combine($this.CacheDirectory, $this.CacheFileName)
    }
    
    OutputCache([string]$CacheFileName, [int]$CacheDurationInSeconds) {
        $this.CacheFileName = $CacheFileName
        $this.CacheDurationInSeconds = $CacheDurationInSeconds
        $this.CachePath = [IO.Path]::Combine($this.CacheDirectory, $this.CacheFileName)
    }

    [bool]IsCacheValid() {
        if ([IO.Path]::Exists($this.CachePath)) {
            $fileAge = (Get-Date) - (Get-Item $this.CachePath).LastWriteTime
            return $fileAge.TotalSeconds -lt $this.CacheDurationInSeconds
        }
        return $false
    }

    [void]SaveToCache([object]$Data) {
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
}

# Example usage:
# $cache = [OutputCache]::new("c:\path\to\cache.json", 3600)
# $result = $cache.GetOrExecute({ Get-Process })