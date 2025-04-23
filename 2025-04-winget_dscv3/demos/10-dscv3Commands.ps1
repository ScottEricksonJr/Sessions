## Install dsc and pwsh7
winget.exe install --id Microsoft.DSC
winget.exe install pwsh

## Get the list of available DSC resources
dsc.exe resource list

## Get the list of available adapter based DSC resources
dsc.exe resource list --adapter * 

## Get the paramters for a dscv3 resource
dsc.exe resource schema -r Microsoft/OSInfo

## Get parameters for a classic DSC resource
Get-DscResource registry | select -ExpandProperty properties

## get current state a dsc config
dsc.exe config get -f 11-dscv3-simple.dsc.yaml

## test state of a dsc config
dsc.exe config test -f 11-dscv3-simple.dsc.yaml

## apply a dsc config
dsc.exe config set -f 11-dscv3-simple.dsc.yaml

## apply a dsc config with trace level logging
dsc.exe --trace-level trace config set -f 11-dscv3-simple.dsc.yaml

## dsc adapter cache
c:\users\userprofile\appdata\local\dsc

