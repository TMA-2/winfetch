<h3 align="center"><img alt="logo-wide" src="https://user-images.githubusercontent.com/46838874/109414417-d649f500-79d8-11eb-8525-934ea963a4e3.png" width="450px"></h3>

<br />
<p align="center">
<img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/lptstr/winfetch.svg">
<img alt="GitHub license" src="https://img.shields.io/github/license/lptstr/winfetch.svg">
<img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/lptstr/winfetch.svg">
<img alt="Made with: Wordpad" src="https://img.shields.io/badge/made%20with-wordpad-blue.svg">
</p>

<br />
<p align="center">
<img alt="Windows Terminal screenshot" src="https://user-images.githubusercontent.com/46838874/109414247-f75e1600-79d7-11eb-90ea-d28d417b1654.png" width="600px">
</p>
<br />

Winfetch is a command-line system information utility written in PowerShell 5+. Winfetch displays information about your operating system, software and hardware in an aesthetic and visually pleasing way.

The overall purpose of Winfetch is to be used in screenshots of your system. Winfetch shows the information other people want to see. There are other tools available for proper system statistic/diagnostics.

The information by default is displayed alongside your operating system's logo. You can further configure Winfetch to instead use an image, your wallpaper or nothing at all.

<br />
<p align="center">
<img alt="Windows Console screenshot" src="https://user-images.githubusercontent.com/46838874/109414338-620f5180-79d8-11eb-8b73-e360a7913659.png" width="600px">
</p>
<br />

According to [benchmarks](https://github.com/lptstr/winfetch/wiki/Winfetch-vs-Neofetch), Winfetch on Windows is faster than [Neofetch](https://github.com/dylanaraps/neofetch) running on Bash emulators like MSYS (Git Bash) or Cygwin.


#### More: \[[Installation](https://github.com/lptstr/winfetch/wiki/Installation)\] \[[Configuration](https://github.com/lptstr/winfetch/wiki/Configuration)\] \[[Colors](https://github.com/lptstr/winfetch/wiki/ANSI-Colors)\]


## Configuration
This new version implements a cache so longer-running sections like pkgs and ps_pkgs don't run if they're within a timespan (by default, 15 minutes), and `-Cache` is specified.

Cache location: TBD

### File System
**Possible locations**
- `~\.config\winfetch\cache`
- `~\appdata\local\winfetch\cache`

**Filename**: info_section.clixml / info_section.json

Example for `info_`:
```xml
<!-- Fill with sample content -->
```

### Registry
Something like: `HKCU\Software\Winfetch`
```yaml
Configuration:
  	Switches:
  		image: (string) Path to image
    	ascii: (switch) Whether to use ASCII
    	genconf: (switch) Generate config.ps1 off the switches used
    	configpath: (string) Path to config.ps1
    	noimage: (switch) Only show information without logo
    	logo: (string)
    	blink: (switch)
    	stripansi: (switch)
\Cache:
    CacheDate: DateTime of last update
    CacheAge: Timespan between the last time it ran and CacheDate
    \info_<section>:
      Title: The section title
      Content: The section content
      RunTime: Time (ms) it took to run last time -Measure was specified?
      LastRun: If Cached, the datetime it was run
      Cached: (?) If the actual output will be saved in a file path, True/False if it exists
```

###### _For old systems, use the [legacy branch](https://github.com/lptstr/winfetch/tree/legacy)._
