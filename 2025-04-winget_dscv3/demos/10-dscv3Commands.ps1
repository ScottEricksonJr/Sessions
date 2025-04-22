dsc resource list Microsoft.DSC/Assertion | ConvertFrom-Json

$adaptedResources = dsc resource list --adapter * | ConvertFrom-Json

$adaptedResources |
Where-Object requireAdapter -EQ Microsoft.Windows/WindowsPowerShell |
Format-Table -Property type, kind, version, capabilities, description


dsc resource schema -r Microsoft/OSInfo