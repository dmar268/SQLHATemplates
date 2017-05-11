function CreateUnAttendXml()
{
    Param($templatePath, $machineName, $userName, $password)


    [xml] $config = [xml] (Get-Content $templatePath)

    $node = $config.FirstChild.ChildNodes | where { $_.pass -eq "oobeSystem" }
    $node.component.UserAccounts.AdministratorPassword.Value = $password
    $node.component.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $password
    $node.component.UserAccounts.LocalAccounts.LocalAccount.Name = $userName

    $node = $config.FirstChild.ChildNodes | where { $_.pass -eq "specialize" }
    $node.component[0].ComputerName = $machineName
    $node.component[0].AutoLogon.Username = $userName
    $node.component[0].AutoLogon.Password.Value = $password

    $targetPath = Split-Path $templatePath
    $targetPath = Join-Path $targetPath -ChildPath $machineName 
    $targetPath += ".xml"

    $exist = Test-Path $targetPath
    if ($exist)
    {
        Remove-Item $targetPath -Force
    }

    $config.Save($targetPath)
}

$templatePath = "f:\dsc16\deployment\unattend.xml"

CreateUnAttendXml -templatePath $templatePath -machineName test -userName userAccount -password P@ssword