## Get all volumes and their blocksize. SQL data files and logs should be on a volume with a blocksize of 65536 (64k)
Get-CimInstance -ClassName Win32_Volume | Select-Object Name, FileSystem, Label, BlockSize

## Set power plan to high performance
$PowerPlan = Get-CimInstance -ClassName Win32_PowerPlan | Where-Object { $_.IsActive -eq $true }
$PowerPlan | Set-CimInstance -Arguments @{ PowerSettingIndex = 0 } -PassThru | Out-Null

