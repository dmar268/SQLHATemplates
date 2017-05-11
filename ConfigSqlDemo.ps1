Configuration GetMofFile
{
    Node $AllNodes.Where{$_.Role -eq "VMHost" }.NodeName
    {
        $ShareAccessCred = Get-Credential -UserName ($Node.HostShareAccountName) -Message "Enter password for HostShareAccount"

        xVMSwitch demoNetwork
        {
            Name = $Node.DemoNetworkSwitchName
            Type = "Internal"

            Ensure = "Present"
        }

        xIPAddress setStaticIPAddress
        {
            IPAddress      = $Node.HostIPAddressOnInternalSwitch
            InterfaceAlias = "vEthernet (Internal)"
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily

            DependsOn = "[xVMSwitch]demoNetwork" 
        }


        File vmFolder
        {
            Ensure = "Present"
            DestinationPath = $Node.VhdPath
            Type = "Directory"

            DependsOn = "[xIPAddress]setStaticIPAddress"
        }


        User vmUser
        {
            UserName = $Node.HostShareAccountName
            Password = $ShareAccessCred

            Ensure = "Present"

            DependsOn = "[File]vmFolder" 
        }


        xSmbShare SqlSrcShare
        {
            Ensure = "Present" 
            Name   = $Node.SqlShareName
            Path = $Node.SqlSrcHostPath
            ReadAccess = "$env:COMPUTERNAME\$($Node.HostShareAccountName)"

            DependsOn = "[User]vmUser"  
        }

#pdc
        CreateUnAttendXml -templatePath $Node.UnattendxmlPath -machineName "pdc" -userName $Node.VMAdministratorName -password $Node.VMAdministratorPassword
        
        xVHD vhdPrepDC
        {
            Name = $Node.Pdc.VhdName
            Path = $Node.VhdPath
            ParentPath = $Node.VhdSrcPath
            Generation = "Vhd"
            Ensure = "Present"

            DependsOn = "[xSmbShare]SqlSrcShare"  
        }

        xVhdFile VHDPrepDC
        {
            VhdPath = Join-Path $Node.VhdPath -ChildPath $($Node.Pdc.VhdName + ".vhd")

            FileDirectory = ($Node.FilesToCopy + $Node.Pdc.FilesToCopy) | % {
                MSFT_xFileDirectory {
                    SourcePath = $_.SourcePath
                    DestinationPath = $_.DestinationPath
                    Ensure = "Present"
                    Type = $_.Type
                    Recurse = $_.Recurse
                    Force = $true
                }
            }

            DependsOn = "[xVHD]vhdPrepDC"   
        }
        
        xVMHyperV pdc
        {
            Name = "SqlDemo-pdc"

            Ensure = "Present"

            VhDPath = Join-Path $Node.VhdPath -ChildPath $($Node.Pdc.VhdName + ".vhd")      
            SwitchName = $Node.DemoNetworkSwitchName

            State = "Running"
            StartupMemory = $Node.MemorySize
            ProcessorCount = $Node.ProcessorCount

            DependsOn = "[xVhdFile]VHDPrepDC"            
        }


#sql01
        CreateUnAttendXml -templatePath $Node.UnattendxmlPath -machineName "sql01" -userName $Node.VMAdministratorName -password $Node.VMAdministratorPassword
        

        xVHD VHDPrepSql01
        {
            Name = $Node.Sql01.VhdName
            Path = $Node.VhdPath
            ParentPath = $Node.VhdSrcPath
            Generation = "Vhd"
            Ensure = "Present"

            DependsOn = "[xSmbShare]SqlSrcShare"  
        }

        xVhdFile VHDPrepSql01
        {
            VhdPath = Join-Path $Node.VhdPath -ChildPath $($Node.Sql01.VhdName + ".vhd")

            FileDirectory = ($Node.FilesToCopy + $Node.Sql01.FilesToCopy)  | % {
                MSFT_xFileDirectory {
                    SourcePath = $_.SourcePath
                    DestinationPath = $_.DestinationPath
                    Ensure = "Present"
                    Type = $_.Type
                    Recurse = $_.Recurse
                    Force = $true
                }
            }

            DependsOn = "[xVHD]VHDPrepSql01"   
        }

        xVMHyperV Sql01
        {
            Name = "SqlDemo-Sql01"

            Ensure = "Present"

            VhDPath = Join-Path $Node.VhdPath -ChildPath $($Node.Sql01.VhdName + ".vhd")          
            SwitchName = $Node.DemoNetworkSwitchName

            State = "Running"
            StartupMemory = $Node.MemorySizeSql
            ProcessorCount = $Node.ProcessorCount

            DependsOn = "[xVhdFile]VHDPrepSql01"            
        }

#sql02
        CreateUnAttendXml -templatePath $Node.UnattendxmlPath -machineName "sql02" -userName $Node.VMAdministratorName -password $Node.VMAdministratorPassword

        xVHD VHDPrepSql02
        {
            Name = $Node.Sql02.VhdName
            Path = $Node.VhdPath
            ParentPath = $Node.VhdSrcPath
            Generation = "Vhd"
            Ensure = "Present"

            DependsOn = "[xSmbShare]SqlSrcShare"  
        }

        xVhdFile VHDPrepSql02
        {
            VhdPath = Join-Path $Node.VhdPath -ChildPath $($Node.Sql02.VhdName + ".vhd")

            FileDirectory = ($Node.FilesToCopy + $Node.Sql02.FilesToCopy)  | % {
                MSFT_xFileDirectory {
                    SourcePath = $_.SourcePath
                    DestinationPath = $_.DestinationPath
                    Ensure = "Present"
                    Type = $_.Type
                    Recurse = $_.Recurse
                    Force = $true
                }
            }

            DependsOn = "[xVHD]VHDPrepSql02"   
        }

        xVMHyperV Sql02
        {
            Name = "SqlDemo-Sql02"

            Ensure = "Present"

            VhDPath = Join-Path $Node.VhdPath -ChildPath $($Node.Sql02.VhdName + ".vhd")          
            SwitchName = $Node.DemoNetworkSwitchName

            State = "Running"
            StartupMemory = $Node.MemorySizeSql
            ProcessorCount = $Node.ProcessorCount

            DependsOn = "[xVhdFile]VHDPrepSql02"            
        }

    }
}


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


GetMofFile -ConfigurationData $PSScriptRoot\ConfigSqlDemoData.psd1