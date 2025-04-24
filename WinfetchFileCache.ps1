# Manual cache, writes to JSON as well as local cache
# TODO: Test!

class WinfetchCacheFile {
    #region: Properties
    [string]$CacheFilePath = ([environment]::GetEnvironmentVariable('temp', 'User') + '\winfetch\Cache.json')
    [int]$MaxAgeInSeconds = 900
    [pscustomobject]$Data = [pscustomobject]@{
        WingetVersion = '2.5.1'
        Created = [datetime]::Now.ToString('s')
    }
    #endregion: Properties

    #region: Constructor
    WinfetchCacheFile() {
        $this.Initialize()
    }

    WinfetchCacheFile([int]$maxAgeInSeconds) {
        $this.MaxAgeInSeconds = $maxAgeInSeconds
        $this.Initialize()
    }

    WinfetchCacheFile([string]$cacheFilePath, [int]$maxAgeInSeconds) {
        $this.CacheFilePath = $cacheFilePath
        $this.MaxAgeInSeconds = $maxAgeInSeconds
        $this.Initialize()
    }
    #endregion: Constructor

    #region: Methods
    static [WinfetchCacheFile] Default () {
        return [WinfetchCacheFile]::new()
    }

    # Get the cached file data or create the file
    hidden [void] Initialize() {
        # If cache file exists...
        if (Test-Path $this.CacheFilePath) {
            # Retrieve the file data
            $this.Data = Get-Content $this.CacheFilePath | ConvertFrom-Json
        }
        # Otherwise...
        else {
            # Create the path, and set Data to an empty object
            New-Item -Path ([System.IO.FileInfo]::new($this.CacheFilePath)) -ItemType File -Force
            $this.Data = [pscustomobject]@{ }
        }
    }

    hidden [bool] ValidateItem([string]$functionName) {
        # Check if the item exists in the cache
        $CacheData = $this.Data.$functionName
        if($CacheData) {
            # Check if the item is still valid
            $age = [datetime]::Now - [datetime]::Parse($CacheData.Timestamp)
            if ($age.TotalSeconds -le $this.MaxAgeInSeconds) {
                return $true
            } else {
                # Remove the item if it is expired
                $this.Data.psobject.Properties.Remove($functionName)
                $this.SaveCacheToFile()
                return $false
            }
        } else {
            return $false
        }
    }

    # Add the function name and output data to the cache. The function should be executed before calling.
    [void] WriteItem([string]$functionName, [object]$data) {
        <# {
            "function_title": {
                "title": "function_title",
                "data": {
                    "title": "Output Title",
                    "content": "Output Data"
                },
                "timestamp": "Date/Time String"
            },
            "info_the_2nd": {...}
        } #>
        $CacheData = [pscustomobject]@{
            Title = $functionName
            Output = $data -as [pscustomobject]
            Timestamp = (Get-Date).ToString('s')
        }
        $this.Data | Add-Member -MemberType NoteProperty -Name $functionName -Value $CacheData
        $this.SaveCacheToFile()
    }

    # Get a given function's output, either from the cache or by executing it
    [pscustomobject] ReadItem([string]$functionName) {
        # If the item exists and is within the age limit, return its content
        if ($this.ValidateItem($functionName)) {
            return $this.Data.$functionName.Content
        }
        # refresh item otherwise
        else {
            # return function content if it exists
            if(gcm $functionName) {
                $output = & $functionName
                # refresh cache and return
                $this.WriteItem($functionName, $output)
                return $output
            }
            else {
                return $null
            }
        }
        # if we somehow get here, something went wrong
        return $null
    }

    # save the cache to file
    [void] SaveCacheToFile() {
        try {
            $this.Data | ConvertTo-Json -Depth 5 | Set-Content -Path $this.CacheFilePath
        } catch {
            $Err = $_
            Throw "Exception $($Err.Exception.HResult) writing cache to file > $($Err.Exception.Message)"
        }
    }
    #endregion: Methods
}

function _TestCache {
    function info_test {
        return @{
            Title   = 'Function Title'
            Content = "Value from $($MyInvocation.MyCommand.Name)"
        }
    }

    # SECTION: Example usage...
    # Initialize class @ 15s (for testing purposes)
    $cache = [WinfetchCacheFile]::new(15)

    # Call function
    $FunctionOutput = & info_test

    # Write output to cache
    $cache.WriteItem('info_test', $FunctionOutput)

    # Read output from cache
    $FunctionOutputCached = $cache.ReadItem('info_test')

    # Wait 15 seconds so the item expires
    sleep -s 15


}