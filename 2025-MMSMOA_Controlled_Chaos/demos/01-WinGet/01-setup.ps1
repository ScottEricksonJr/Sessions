## Repair the WinGet Package Manager/Make sure its installed
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Repair-WinGetPackageManager -Force -Latest

## Enable Winget Configuration
winget.exe configure --enable
