# Writes to manual cache, does not write to persistent file
# TODO: Use psobject instead of hashtable
# TODO: Add writing to persistent json file
# Taken from MartinGC94\UsefulArgumentCompleters and modified

using namespace System
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Runtime.Caching
using namespace System.Collections.Generic

# NOTE: Working
class WinfetchCache {
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
        if ([WinfetchCache]::ObjectCache.TryGetValue($Command, [ref] $Result))
        {
            return $Result
        }
        $Result = if (!$ValidateInput -or [WinfetchCache]::CommandIsSafe($Command))
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
        [WinfetchCache]::ObjectCache.Add($Command, $Result)
        return $Result
    }
}

