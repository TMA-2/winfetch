BeforeAll {
    # Import each class to test
    $Classes = @(
        '.\..\CacheMemory.ps1'
        '.\..\CacheMemoryFile.ps1'
        '.\..\WinfetchCache.ps1'
        '.\..\WinfetchFileCache.ps1'
    ) | ForEach-Object {
        if (Test-Path -Path $_) {
            .$Path
        }
    }
}

Describe "Winget Tests" {
    Context "Winget info_ Functions" {
        It "Should return 25 functions by default" {
            $wingetoutput = winfetch -genconf -noimage
            $wingetoutput | Should -HaveCount 25
        }
    }
}

Describe "Winget Features" {
    Context "Winget Caching" {
        $CachePath = "$env:USERPROFILE\.config\winfetch\cache.json"
        $wingetoutput = winfetch -genconf -noimage -cache -showpkgs @('winget')
        $json = Get-Content $CachePath -Raw | ConvertFrom-Json

        It "Should output a cache file" {
            gi $CachePath | Should -Exist
        }

        It "Should contain a valid JSON file" {
            $json | Should -NotBeNullOrEmpty
            $json | Should -Contain -ExpectedValue "WingetVersion"
            $json | Should -Contain -ExpectedValue "Cache"
            $json.Cache | Should -BeOfType [pscustomobject[]]
        }
        # winget cache if enabled
        if(gcm winget -ea 0) {
            It "Should contain a winget cache" {
                $json.Cache | Should -Contain -ExpectedValue "info_pkgs"
                $json.Cache.info_pkgs.content | Should -Match '\d+ \(winget\)'
                $wingetoutput.Cache | Should -BeOfType [System.Collections.Generic.Dictionary[string,object]]
            }
        }
    }
}