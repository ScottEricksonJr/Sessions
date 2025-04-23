## Enable Winget Configuration
winget.exe configure --enable

## Run a configuration file, suppress config agreements
winget.exe configure --config 01-simple.winget  --accept-configuration-agreements

## Install the winget powershell module
install-module Microsoft.WinGet.Client -Scope AllUsers

## Install WinGet on Server 2019/2022 - https://github.com/asheroto/winget-install
Install-Script winget-install -Force
winget-install -force

## see all the available versions of an app in the repository
winget.exe show Microsoft.VisualStudioCode --versions

## launch winget configure pointing to a url
winget.exe configure https://aka.ms/sandbox.dsc.yaml

## View application that can be upgraded with winget
winget.exe upgrade

## Install all available upgrades
winget.exe upgrade --all

## Open Winget log location
winget.exe --logs

## WinGet settings reference
https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md

## Dealing with running winget in a SYSTEM context. 
Set-Location "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
.\winget.exe install 7zip.7zip --force --accept-package-agreements --accept-source-agreements

###### ConfigMgr compliance setting example
    ## Discovery script
    $appid = 'Microsoft.PowerShell.Preview'

    Set-Location "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    $installedApps = .\winget.exe list --accept-source-agreements
    if ($installedApps -like "*$appid*") {
        return $true
    } else {
        return $false
    }
    ## Remediation script
    $appid = 'Microsoft.PowerShell.Preview'
    Set-Location "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    .\winget.exe install --id $appid --force --accept-package-agreements --accep`t-source-agreements