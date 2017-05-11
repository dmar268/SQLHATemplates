# pdc 

Configuration GetMofFile
{

    param(
    $domainAdminCred,
    $sqlServiceCred,
    $SQLSaCred,
    $installCred)

    Node $AllNodes.Where{$_.Role -eq "PrimaryDomainController" }.NodeName
    {

        xIPAddress setStaticIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            DefaultGateway = $Node.DefaultGateway
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily
        }

        xDNSServerAddress setDNS
        {
            Address        = $Node.DnsAddress
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily

            DependsOn = "[xIPAddress]setStaticIPAddress"
        }

        
        WindowsFeature DCFeature
        {
            Ensure = "Present"

            Name      = "AD-Domain-Services"

            DependsOn = "[xDNSServerAddress]setDNS"
        }

        xADDomain CreateForest
        {
            DomainName = $Node.DomainFullName
            DomainAdministratorCredential = $domainAdminCred
            SafemodeAdministratorPassword = $domainAdminCred

            DependsOn = "[WindowsFeature]DCFeature"
        }

        File createBackupFolder
        {
            Ensure = "Present"
            DestinationPath = $Node.SqlBackupFolderName
            Type = "Directory"

            DependsOn = "[xADDomain]CreateForest"
        }


        xSmbShare setSqlBackupShare
        {
            Ensure = "Present"
            Name = $Node.SqlBackupShareName
            Path = $Node.SqlBackupFolderName
            FullAccess = $sqlServiceCred.UserName

            DependsOn = "[File]createBackupFolder"
        }

        LocalConfigurationManager 
        { 
            CertificateId = $node.Thumbprint 
            RebootNodeIfNeeded = $true
        } 
    }


    Node $AllNodes.Where{$_.Role -eq "PrimarySqlClusterNode" }.NodeName
    {
 
    
        xIPAddress setStaticIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            DefaultGateway = $Node.DefaultGateway
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily
        }

        xDNSServerAddress setDNS
        {
            Address        = $Node.DnsAddress
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily

            DependsOn = "[xIPAddress]setStaticIPAddress"
        }

        
        # AD
        WindowsFeature ADPS
        {
            Ensure = "Present"
            Name      = "RSAT-AD-PowerShell"

            DependsOn = "[xDNSServerAddress]setDNS"
        }

        WindowsFeature FailoverFeature
        {
            Ensure = "Present"
            Name      = "Failover-clustering"

            DependsOn = "[WindowsFeature]ADPS"
        }

        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-PowerShell"   

            DependsOn = "[WindowsFeature]FailoverFeature"
        }

        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-CmdInterface"

            DependsOn = "[WindowsFeature]RSATClusteringPowerShell"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainFullName
            DomainUserCredential = $domainAdminCred
            RetryCount = 10
            RetryIntervalSec = 300

            DependsOn = "[WindowsFeature]RSATClusteringCmdInterface"
        }

        xComputer ensureName
        {
            Name       = $Node.Name
            DomainName = $Node.DomainFullName
            Credential = $domainAdminCred

            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        
        # Install SQL Server
        WindowsFeature installdotNet35
        {            
            Ensure = "Present"
            Name = "Net-Framework-Core"
            Source = $Node.DotNetSxS

            DependsOn = "[xComputer]ensureName"
        }
        
        xSqlServerInstall installSqlServer
        {
            InstanceName = $Node.SqlInstanceName

            SourcePath = "\\$env:COMPUTERNAME\$($Node.SqlShareName)"
            SourcePathCredential = $installCred
            
            Features= $Node.SqlInstallFeatures
            SqlAdministratorCredential = $SQLsaCred

            DependsOn = "[WindowsFeature]installdotNet35"
        }

        xFireWall enableRemoteAccessOnSQLBrowser
        {

            Name = "SqlBrowser"
            Ensure = "Present"
            Access = "Allow"
            State ="Enabled"
            ApplicationPath = Join-Path ${env:ProgramFiles(x86)} -ChildPath "Microsoft SQL Server\90\Shared\sqlbrowser.exe"
            Profile = "Any"

            DependsOn = "[xSqlServerInstall]installSqlServer"
        }

        xFireWall enableRemoteAccessOnSQLEngine
        {
            Name = "SqlServer"
            Ensure = "Present"
            Access = "Allow"
            State ="Enabled"
            ApplicationPath = Join-Path $env:ProgramFiles -ChildPath "Microsoft SQL Server\MSSQL11.$($Node.SqlInstanceName)\MSSQL\Binn\sqlservr.exe"
            Profile = "Any"

            DependsOn = "[xFireWall]enableRemoteAccessOnSQLBrowser"
        }
      

        # config SQL Server to HAG

        xCluster createOrJoinCluster
        {
            Name = $Node.ClusterName
            StaticIPAddress = $Node.ClusterIPAddress
            DomainAdministratorCredential = $domainAdminCred

            DependsOn = "[xFireWall]enableRemoteAccessOnSQLEngine"
        }

        xSqlHAService config
        {
            InstanceName = $Node.SqlServerInstance
            SqlAdministratorCredential = $SQLsaCred
            ServiceCredential = $sqlServiceCred

            DependsOn = "[xCluster]createOrJoinCluster"
        }
           
        xSqlHAEndPoint configEndPoint
        {
            InstanceName = $Node.SqlServerInstance
            AllowedUser = $sqlServiceCred.UserName
            Name = $Node.EndPointName

            DependsOn = "[xSqlHAService]config"
        }
  
        xSqlHAGroup createOrJoinHAG
        {
            Name = $Node.AvailabilityGroup
            Database = $Node.Database
            ClusterName = $Node.ClusterName
            DatabaseBackupPath = $Node.BackupShare

            InstanceName = $Node.SqlServerInstance
            EndpointName = $Node.EndPointURL

            DomainCredential = $domainAdminCred
            SqlAdministratorCredential = $SQLsaCred
            
            DependsOn = "[xSqlHAEndPoint]configEndPoint"
        } 
        
        LocalConfigurationManager 
        { 
            CertificateId = $node.Thumbprint 
            RebootNodeIfNeeded = $true
        } 
    }

    Node $AllNodes.Where{ $_.Role -eq "ReplicaSqlServerNode" }.NodeName
    {
      
        xIPAddress setStaticIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            DefaultGateway = $Node.DefaultGateway
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily
        }

        xDNSServerAddress setDNS
        {
            Address        = $Node.DnsAddress
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily

            DependsOn = "[xIPAddress]setStaticIPAddress"
        }
        

        WindowsFeature ADPS
        {
            Ensure = "Present"
            Name      = "RSAT-AD-PowerShell"

            DependsOn = "[xDNSServerAddress]setDNS"
        }

        WindowsFeature FailoverFeature
        {
            Ensure = "Present"
            Name      = "Failover-clustering"

            DependsOn = "[WindowsFeature]ADPS"            
        }

        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-PowerShell"   

            DependsOn = "[WindowsFeature]FailoverFeature"
        }

        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-CmdInterface"

            DependsOn = "[WindowsFeature]RSATClusteringPowerShell"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainFullName
            DomainUserCredential = $domainAdminCred
            RetryCount = 10
            RetryIntervalSec = 300

            DependsOn = "[WindowsFeature]RSATClusteringCmdInterface"
        }

        xComputer ensureName
        {
            Name       = $Node.Name
            DomainName = $Node.DomainFullName
            Credential = $domainAdminCred

            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
        
        # Install SQL Server

        WindowsFeature installdotNet35
        {
            Ensure = "Present"
            Name = "Net-Framework-Core"
            Source = $Node.DotNetSxS

            DependsOn = "[xComputer]ensureName"
        }
        
        xSqlServerInstall installSqlServer
        {
            InstanceName = $Node.SqlInstanceName

            SourcePath = "\\$env:COMPUTERNAME\$($Node.SqlShareName)"
            SourcePathCredential = $installCred
            
            Features= $Node.SqlInstallFeatures
            SqlAdministratorCredential = $SQLsaCred

            DependsOn = "[WindowsFeature]installdotNet35"
        }

        xFireWall enableRemoteAccessOnSQLBrowser
        {

            Name = "SqlBrowser"
            Ensure = "Present"
            Access = "Allow"
            State ="Enabled"
            ApplicationPath = Join-Path ${env:ProgramFiles(x86)} -ChildPath "Microsoft SQL Server\90\Shared\sqlbrowser.exe"
            Profile = "Any"

            DependsOn = "[xSqlServerInstall]installSqlServer"
        }

        xFireWall enableRemoteAccessOnSQLEngine
        {
            Name = "SqlServer"
            Ensure = "Present"
            Access = "Allow"
            State ="Enabled"
            ApplicationPath = Join-Path $env:ProgramFiles -ChildPath "Microsoft SQL Server\MSSQL11.$($Node.SqlInstanceName)\MSSQL\Binn\sqlservr.exe"
            Profile = "Any"

            DependsOn = "[xFireWall]enableRemoteAccessOnSQLBrowser"
        }

        # config SQL 

        xWaitForCluster waitForCluster
        {
            Name = $Node.ClusterName
            RetryIntervalSec = 10
            RetryCount = 60

            DependsOn = "[xFireWall]enableRemoteAccessOnSQLEngine"
        }

        xCluster joinCluster
        {
            Name = $Node.ClusterName
            StaticIPAddress = $Node.ClusterIPAddress
            DomainAdministratorCredential = $domainAdminCred

            DependsOn = "[xWaitForCluster]waitForCluster"
        }
    
        xSqlHAService configSQLService
        {
            InstanceName = $Node.SqlServerInstance
            SqlAdministratorCredential = $SQLsaCred
            ServiceCredential = $sqlServiceCred

            DependsOn = "[xCluster]joinCluster"
        }

        xSqlHAEndPoint configEndPoint
        {
            InstanceName = $Node.SqlServerInstance
            AllowedUser = $sqlServiceCred.UserName
            Name = $Node.EndPointName

            DependsOn = "[xSqlHAService]configSQLService"
        }

        xWaitForSqlHAGroup waitForHAG
        {
            Name = $Node.AvailabilityGroup
            ClusterName = $Node.ClusterName
            RetryIntervalSec = 10
            RetryCount = 10

            InstanceName = $Node.SqlServerInstance

            DomainCredential = $domainAdminCred
            SqlAdministratorCredential = $SQLsaCred

            DependsOn = "[xSqlHAEndPoint]configEndPoint"
        }

        xSqlHAGroup joinHAG
        {
            Database = $Node.Database
            Name = $Node.AvailabilityGroup
            ClusterName = $Node.ClusterName
            DatabaseBackupPath = $Node.BackupShare

            InstanceName = $Node.SqlServerInstance
            EndpointName = $Node.EndPointURL

            DomainCredential = $domainAdminCred
            SqlAdministratorCredential = $SQLsaCred
            
            DependsOn = "[xWaitForSqlHAGroup]waitForHAG"
        }

        LocalConfigurationManager 
        { 
            CertificateId = $node.Thumbprint 
            RebootNodeIfNeeded = $true
        } 

     
    }
}


$domainAdminCred = Get-Credential -UserName "SqlDemo\Administrator" -Message "Enter password for private domain Administrator"
$sqlServiceCred = $domainAdminCred


$SQLSaCred = Get-Credential -UserName "sa" -Message "Enter password for Sql Administrator"

$installCred = Get-Credential -UserName "$env:COMPUTERNAME\vmuser" -Message "Enter password for HostShareAcount"


GetMofFile -ConfigurationData $PSScriptRoot\..\ConfigSqlDemoData.psd1 -domainAdminCred $domainAdminCred -sqlServiceCred $sqlServiceCred -SQLSaCred $SQLSaCred -installCred $installCred
