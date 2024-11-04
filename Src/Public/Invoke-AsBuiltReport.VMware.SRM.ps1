function Invoke-AsBuiltReport.VMware.SRM {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of VMware SRM in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.6
        Author:         Matt Allford (@mattallford)
        Editor:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         @rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    Write-PScriboMessage -IsWarning "Please refer to the AsBuiltReport.VMware.SRM github website for more detailed information about this project."
    Write-PScriboMessage -IsWarning "Do not forget to update your report configuration file after each new version release."
    Write-PScriboMessage -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM"
    Write-PScriboMessage -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/issues"

    # Check the current AsBuiltReport.VMware.SRM module
    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.VMware.SRM -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -IsWarning "AsBuiltReport.VMware.SRM $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.VMware.SRM -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -IsWarning "AsBuiltReport.VMware.SRM $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -IsWarning "Run 'Update-Module -Name AsBuiltReport.VMware.SRM -Force' to install the latest version."
            }
        }
    } Catch {
        Write-PScriboMessage -IsWarning $_.Exception.Message
    }
    # Check if the required version of VMware PowerCLI is installed
    Get-AbrSRMRequiredModule -Name 'VMware.PowerCLI' -Version '13.1'

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $script:TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    #---------------------------------------------------------------------------------------------#
    #                                 Connection Section                                          #
    #---------------------------------------------------------------------------------------------#
    foreach ($VIServer in $Target) {
        #region Protect Site vCenter connection
        try {
            Write-PScriboMessage "Connecting to SRM protected site vCenter: $($VIServer) with provided credentials."
            $script:LocalvCenter = Connect-VIServer $VIServer -Credential $Credential -Port 443 -Protocol https -ErrorAction Stop
            if ($LocalvCenter) {
                Write-PScriboMessage "Successfully connected to SRM protected site vCenter: $($LocalvCenter.Name)."
            }
        } catch {
            Write-PScriboMessage -IsWarning  "Unable to connect to SRM protected site vCenter Server $($VIServer))."
            Write-Error "$($_) (Protected vCenter Connection)."
            throw
        }
        #endregion Protect Site vCenter connection

        #region Protect Site SRM connection
        try {
            Write-PScriboMessage "Connecting to SRM server at protected site with provided credentials."
            $script:LocalSRM = Connect-SrmServer -IgnoreCertificateErrors -ErrorAction Stop -Port 443 -Protocol https -Credential $Credential -Server $LocalvCenter
            if ($LocalSRM) {
                Write-PScriboMessage "Successfully connected to SRM server at protected site: $($LocalSRM.Name) with provided credentials."
                $script:ProtectedSiteName = $LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName
                $script:RecoverySiteName = $LocalSRM.ExtensionData.GetPairedSite().Name
            }
        } catch {
            Write-PScriboMessage -IsWarning  "Unable to connect to SRM server at protected site."
            Write-Error "$($_) (Local SRM Connection)."
            throw
        }
        #endregion Protect Site SRM connection

        #region Recovery Site vCenter connection
        try {
            $script:RemotevCenter = Connect-VIServer $LocalSRM.ExtensionData.GetPairedSite().vcHost -Credential $Credential -Port 443 -Protocol https -ErrorAction SilentlyContinue
            if ($RemotevCenter) {
                Write-PScriboMessage "Connected to $((Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value)."
                try {
                    Write-PScriboMessage "Connecting to SRM server at recovery site with provided credentials."
                    $script:RemoteSRM = Connect-SrmServer -IgnoreCertificateErrors -Server $RemotevCenter -Credential $Credential -Port 443 -Protocol https -RemoteCredential $Credential
                    if ($RemoteSRM) {
                        Write-PScriboMessage "Successfully connected to SRM server at recovery site: $($RemoteSRM.Name) with provided credentials."
                    }
                } catch {
                    Write-PScriboMessage -IsWarning  "Unable to connect to SRM server at recovery site."
                    Write-Error $_
                    throw
                }
            }
        } catch {
            Write-Error $_
        }
        #endregion Recovery Site vCenter connection

        #region VMware SRM As Built Report
        # If Protected Site exists, generate VMware SRM As Built Report
        if ($LocalSRM) {
            Section -Style Heading1 "$($LocalSRM.Name.split(".", 2).toUpper()[0])" {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "VMware Site Recovery Manager is an extension to VMware vCenter Server that delivers a business continuity and disaster recovery solution that helps you plan, test, and run the recovery of vCenter Server virtual machines."
                    BlankLine
                }

                Write-PScriboMessage "Sites InfoLevel set at $($InfoLevel.Sites)."
                if ($InfoLevel.Sites -ge 1) {
                    Get-AbrSRMSitePair
                }


                Write-PScriboMessage "License InfoLevel set at $($InfoLevel.License)."
                if ($InfoLevel.License -ge 1) {
                    Get-AbrSRMLicense
                }

                Write-PScriboMessage "Permission InfoLevel set at $($InfoLevel.Permission)."
                if ($InfoLevel.Permission -ge 1) {
                    Get-AbrSRMPermission
                }

                Write-PScriboMessage "SRA InfoLevel set at $($InfoLevel.SRA)."
                if ($InfoLevel.SRA -ge 1) {
                    Get-AbrSRMStorageReplicationAdapter
                }

                Write-PScriboMessage "Array Pairs InfoLevel set at $($InfoLevel.ArrayPairs)."
                if ($InfoLevel.ArrayPairs -ge 1) {
                    Get-AbrSRMArrayPair
                }

                Write-PScriboMessage "Network Mapping InfoLevel set at $($InfoLevel.NetworkMapping)."
                if ($InfoLevel.NetworkMapping -ge 1) {
                    Get-AbrSRMNetworkMapping
                }

                Write-PScriboMessage "Folder Mapping InfoLevel set at $($InfoLevel.FolderMapping)."
                if ($InfoLevel.FolderMapping -ge 1) {
                    Get-AbrSRMFolderMapping
                }

                Write-PScriboMessage "Resource Mapping InfoLevel set at $($InfoLevel.ResourceMapping)."
                if ($InfoLevel.ResourceMapping -ge 1) {
                    Get-AbrSRMResourceMapping
                }

                Write-PScriboMessage "Placeholder Datastores InfoLevel set at $($InfoLevel.PlaceholderDatastores)."
                if ($InfoLevel.PlaceholderDatastores -ge 1) {
                    Get-AbrSRMPlaceholderDatastore
                }

                Write-PScriboMessage "Protection Group Site InfoLevel set at $($InfoLevel.ProtectionGroup)."
                if ($InfoLevel.ProtectionGroup -ge 1) {
                    Get-AbrSRMProtectionGroup
                }

                Write-PScriboMessage "Recovery Plan InfoLevel set at $($InfoLevel.RecoveryPlan)."
                if ($InfoLevel.RecoveryPlan -ge 1) {
                    Get-AbrSRMRecoveryPlan
                }
                if ($InfoLevel.Summary -ge 1) {
                    Get-AbrVRMSProtection
                }
            }
        }
        #endregion VMware SRM As Built Report
    }
    #endregion foreach loop
}
