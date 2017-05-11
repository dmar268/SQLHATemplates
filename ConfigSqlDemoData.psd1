# Hash Table to define the environment



@{
    AllNodes = @(

        # Data for VMHost
        @{
            NodeName= "localhost"
            Role = "VMHost"

            VMAdministratorName = "Administrator"
            VMAdministratorPassword = "P@ssword"
            CertSubject = "CN=DSCDemo"

            VhdSrcPath = "c:\SqlDemo\9600.16415.amd64fre.winblue_refresh.130928-2229_server_serverdatacentereval_en-us.vhd"
            
            MemorySize = 2GB
            MemorySizeSql = 4GB 
            ProcessorCount = 4         

            # Host
            DemoNetworkSwitchName = "Internal"
            HostIPAddressOnInternalSwitch = "192.168.100.100"
            SubnetMask     = 24
            AddressFamily  = "IPv4"

            UnattendxmlPath = "$PSScriptRoot\deployment\unattend.xml"
            VhdPath = "$PSScriptRoot\vm"

            FilesToCopy = @(
                    @{ 
                       SourcePath = "$PSScriptRoot\Demo_DSC";                  
                       DestinationPath = "Windows\System32\WindowsPowerShell\v1.0\Modules\Demo_DSC" 
                       Type = "Directory"
                       Recurse = $true
                    }
                    @{ 
                       SourcePath = "$PSScriptRoot\deployment";                
                       DestinationPath = "deployment" 
                       Type = "Directory"
                       Recurse = $true
                     }
                    @{ 
                       SourcePath = "$PSScriptRoot\deployment\Run.ps1";        
                       DestinationPath = "Windows\System32\Configuration\Run.ps1" 
                       Type = "File"
                    }
                    @{ 
                       SourcePath = "C:\Keys\Dscdemo.pfx";        
                       DestinationPath = "deployment\Dscdemo.pfx" 
                       Type = "File"
                    }
            );

            Pdc = @{
                VhdName = "pdc"
                FilesToCopy = @(
                    @{ 
                         SourcePath = "$PSScriptRoot\GetMofFile\pdc.mof"; 
                         DestinationPath = "Windows\System32\Configuration\localhost.mof" 
                         Type = "Directory"
                         Recurse = $true
                    }
                    @{ 
   		                 SourcePath = "$PSScriptRoot\GetMofFile\pdc.meta.mof"; 
                         DestinationPath = "Windows\System32\Configuration\localhost.meta.mof" 
                         Type = "File"
                    }
                    @{ 
                         SourcePath = "$PSScriptRoot\deployment\pdc.xml"; 
                         DestinationPath = "unattend.xml" 
                         Type = "File"
                    }
                );  
            };

            Sql01 = @{
                VhdName = "sql01"
              
                FilesToCopy = @(
                    @{ 
   		                 SourcePath = "$PSScriptRoot\GetMofFile\sql01.mof"; 
                         DestinationPath = "Windows\System32\Configuration\localhost.mof" 
                         Type = "File"
                    }
                    @{ 
   		                 SourcePath = "$PSScriptRoot\GetMofFile\sql01.meta.mof"; 
                         DestinationPath = "Windows\System32\Configuration\localhost.meta.mof" 
                         Type = "File"
                    }
                    @{ 
                         SourcePath = "$PSScriptRoot\deployment\sql01.xml"; 
                         DestinationPath = "unattend.xml" 
                         Type = "File"
                    }
                    @{ 
                         SourcePath = "C:\SqlDemo\Svr12R2\sxs";    
                         DestinationPath = "sxs" 
                         Type = "Directory"
                         Recurse = $true
                    }
                );  
            };

            Sql02 = @{
                VhdName = "sql02"
                FilesToCopy = @(
                    @{ 
   		                 SourcePath = "$PSScriptRoot\GetMofFile\sql02.mof"; 
                         DestinationPath = "Windows\System32\Configuration\localhost.mof" 
                         Type = "File"
                    }
                    @{ 
   		                 SourcePath = "$PSScriptRoot\GetMofFile\sql02.meta.mof"; 
                         DestinationPath = "Windows\System32\Configuration\localhost.meta.mof" 
                         Type = "File"
                    }
                    @{ 
                         SourcePath = "$PSScriptRoot\deployment\sql02.xml"; 
                         DestinationPath = "unattend.xml" 
                         Type = "File"
                    }
                    @{ 
                         SourcePath = "C:\SqlDemo\Svr12R2\sxs";    
                         DestinationPath = "sxs" 
                         Type = "Directory"
                         Recurse = $true
                    }
                );  
            };
        }

        # data for VMs

        @{
            NodeName= "*"

            CertificateFile = "C:\keys\Dscdemo.cer"
            Thumbprint = "E513EEFCB763E6954C52BA66A1A81231BF3F551E"

            InterfaceAlias = "Ethernet"            
            DefaultGateway = "192.168.100.7"
            SubnetMask     = 24
            AddressFamily  = "IPv4"

            DnsAddress = "192.168.100.7"

            DomainName = "SqlDemo"
            DomainFullName = "SqlDemo.Contoso.com"
            DomainAccount = "Administrator"
            
            ClusterName = "SqlC"
            ClusterIPAddress = "192.168.100.10/24"

            Database = "TestDB"
            AvailabilityGroup = "TestAG"
            BackupShare = "\\pdc\backup"

            EndPointName = "TestEndPoint"

            SqlInstallFeatures="SQLEngine,Replication,SSMS"

            SqlInstanceName = "PowerPivot"

            SqlServiceAccountName = "SqlDemo\Administrator"

            SqlAdministratorAccountName = "sa"

            HostShareAccountName = "vmuser"

            DotNetSxS = "C:\SxS"

            SqlSrcHostPath = "C:\SqlDemo\Sql12SP1" 
            SqlShareName = "Sql12SP1"
            SqlFirewallAllowedAddress = "192.168.100.0/24,localsubnet"
        },

        # PDC
        @{
            NodeName= "pdc"
            Role = "PrimaryDomainController"
            Name = "pdc"

            IPAddress  = "192.168.100.7"
            
            SqlBackupFolderName = "c:\backup"
            SqlBackupShareName = "backup"
         },


         # sql01
        @{
            NodeName= "sql01"
            Role = "PrimarySqlClusterNode"
            Name = "sql01"

            IPAddress  = "192.168.100.11"

            SqlServerInstance = "sql01\PowerPivot"

            EndPointURL = "sql01.SQLDemo.Contoso.com:5022"
         },

         # sql02
         @{
            NodeName= "sql02"
            Role = "ReplicaSqlServerNode"
            Name = "sql02"

            IPAddress  = "192.168.100.12"
         
            SqlServerInstance = "sql02\PowerPivot"
 
            EndPointURL = "sql02.SQLDemo.Contoso.com:5022"
         }
    );
}

