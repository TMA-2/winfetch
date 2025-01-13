# TODO: Find a way to add a -NoOutput parameter to the main script in service of only defining the functions
# TODO: Try adding a -Measure switch to show each function's execution time
#   i.e. Terminal (0.35ms): Windows Terminal
#   $cmdtime = Measure-Command -Expression {$info = & "info_$item"}
#   $info['title'] += " ($($cmdtime.TotalMilliseconds)ms):"

BeforeAll {
    $ScriptPath = "$PSScriptRoot\..\winfetch.ps1"
    # dot-source to load the functions and hide the output
    . $ScriptPath | Out-Null
    $WFOutput = winfetch.ps1 -all -stripansi -noimage

    $WFCmds = @("title","dashes","os","computer","kernel","motherboard","uptime","resolution","ps_pkgs","pkgs","pwsh",
        "terminal","theme","cpu","gpu","cpu_usage","memory","disk","battery","locale","weather","local_ip","public_ip",
        "blank","colorbar")
}

Context "winfetch script" {
    It "should return a string" {
        $WFOutput | Should -BeA 'String[]'
    }

    It "should contain 25 items" {
        $WFOutput | Should -HaveCount 25
    }

    # TODO: Check parameters
}

Context "winfetch functions" {
    foreach($item in $WFCmds) {
        Describe $item {
            It "should return a hashtable with title and content keys" {
                $info = & "info_$item"
                $info | Should -BeA 'Hashtable' | Should -HaveMember 'title' | Should -HaveMember 'content'
            }
        }
    }
}
