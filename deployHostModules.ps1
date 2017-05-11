Import-Module $PSScriptRoot\Tools.psm1

get-process wmi* | stop-process -force

CopyFiles -srcPath "$PSScriptRoot\xHyper-V" -dscPath "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Demo_DSC"
