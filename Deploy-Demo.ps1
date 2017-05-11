# deploy demo

. $PSScriptRoot\deployHostModules.ps1
. $PSScriptRoot\deployVMModules.ps1

. $PSScriptRoot\Scenarios\nodes.ps1
. $PSScriptRoot\ConfigSqlDemo.ps1

Start-DscConfiguration -Verbose -Wait -Path .\GetMofFile -ComputerName localhost -force


