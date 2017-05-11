
# deploy VM modules
Import-Module $PSScriptRoot\Tools.psm1

CopyFiles -srcPath "$PSScriptRoot\xNetworking" -dscPath "$PSScriptRoot\Demo_DSC"
CopyFiles -srcPath "$PSScriptRoot\xComputerManagement" -dscPath "$PSScriptRoot\Demo_DSC"
CopyFiles -srcPath "$PSScriptRoot\xActiveDirectory" -dscPath "$PSScriptRoot\Demo_DSC"
CopyFiles -srcPath "$PSScriptRoot\xFailOverCluster" -dscPath "$PSScriptRoot\Demo_DSC"
CopyFiles -srcPath "$PSScriptRoot\xSqlPs" -dscPath "$PSScriptRoot\Demo_DSC"
CopyFiles -srcPath "$PSScriptRoot\xSmbShare" -dscPath "$PSScriptRoot\Demo_DSC"

CopyFiles -srcPath "$PSScriptRoot\Demo_DSC" -dscPath "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Demo_DSC"


