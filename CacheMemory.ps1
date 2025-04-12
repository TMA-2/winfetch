using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Runtime.Caching
using namespace System.Collections.Generic

# investigate using https://learn.microsoft.com/en-us/dotnet/api/system.runtime.caching.cacheitem?view=netframework-4.8.1
# ref: https://learn.microsoft.com/en-us/dotnet/api/system.runtime.caching.memorycache?view=netframework-4.8.1

# cache in memory
class CacheMemory {
    static [MemoryCache]$MemoryCache = [MemoryCache]::new('WinfetchCache')
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
            if ($Unsafe) {
                return $false
            }
        }
        # Check that the function name is expected and exists
        $CommandName = $ParsedTokens.Where({$_.TokenFlags -eq [TokenFlags]::CommandName}).Text
        if ($CommandName -match '^info_\w+' -and (Get-Command $CommandName -ea SilentlyContinue)) {
            return $true
        }
        else {
            return $false
        }
    }

    static [hashtable] GetCachedResults([string] $Command, [bool] $ValidateInput, [int] $CacheDurationInSeconds = 900) {
        # Value exists in cache
        $CacheItem = [CacheMemory]::MemoryCache.GetCacheItem($Command)
        if ($null -ne $CacheItem) {
            return $CacheItem.Value
        }

        $Result = if (!$ValidateInput -or [CacheMemory]::CommandIsSafe($Command)) {
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

        if ($null -ne $Result) {
            $CachePolicy = [CacheItemPolicy]::new()
            $CachePolicy.AbsoluteExpiration = [DateTimeOffset]::Now.AddSeconds($CacheDurationInSeconds)
            [CacheMemory]::MemoryCache.Add($Command, $Result, $CachePolicy)
        }

        return $Result
    }
}