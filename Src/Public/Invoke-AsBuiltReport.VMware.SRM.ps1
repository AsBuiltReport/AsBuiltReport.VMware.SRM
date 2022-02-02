function Invoke-AsBuiltReport.VMware.SRM {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of VMware SRM in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.2
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
    # Check if the required version of VMware PowerCLI is installed
    Get-RequiredModule -Name 'VMware.PowerCLI' -Version '12.3'

    # Import Report Configuration
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    #---------------------------------------------------------------------------------------------#
    #                                 Connection Section                                          #
    #---------------------------------------------------------------------------------------------#
    foreach ($VIServer in $Target) {
        $RemoteCredential = $Credential
        try {
            Write-PScriboMessage "Connecting to protected site vCenter: $($VIServer) with provided credentials"
            $LocalvCenter = Connect-VIServer $VIServer -Credential $Credential -Port 443 -Protocol https -ErrorAction Stop
            if ($LocalvCenter) {
                Write-PScriboMessage "Succefully connected to protected site vCenter: $($LocalvCenter.Name)"
            }
        }
        catch {
            Write-PScriboMessage -IsWarning  "Unable to connect to protected site vCenter Server $($VIServer))"
            Write-Error "$($_) (Protected vCenter Connection)"
            throw
        }

        try {
            Write-PScriboMessage "Testing credentials on protected site SRM"
            $TempSRM = Connect-SrmServer -IgnoreCertificateErrors -ErrorAction Stop -Port 443 -Protocol https -Credential $Credential -Server $LocalvCenter
            if ($TempSRM) {
                Write-PScriboMessage "Succefully Connected to protected site SRM: $($TempSRM.Name) with provided credentials"
            }
        } catch {
            Write-PScriboMessage -IsWarning  "Unable to connect to protected site SRM server"
            Write-Error "$($_) (Local SRM Connection)"
            throw
        }

        try {
            $RemotevCenter = Connect-VIServer $TempSRM.ExtensionData.GetPairedSite().vcHost -Credential $RemoteCredential -Port 443 -Protocol https -ErrorAction SilentlyContinue
            if ($RemotevCenter) {
                Write-PScriboMessage "Connected to $((Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value)"
                try {
                    $RemoteSRM = Connect-SrmServer -IgnoreCertificateErrors -Server $RemotevCenter -Credential $RemoteCredential -Port 443 -Protocol https -RemoteCredential $Credential
                    if ($RemoteSRM) {
                        Write-PScriboMessage "Succefully Connected to recovery site SRM with provided credentials"
                    }
                }
                catch {
                    Write-PScriboMessage -IsWarning  "Unable to connect to recovery site SRM Server"
                    Write-Error $_
                    throw
                }
            }
            if (!$RemotevCenter) {
                try {
                    $RemoteCredential = (Get-Credential -Message "Can not connect to the recovery vCenter with the provided credentials.`r`nEnter $($TempSRM.ExtensionData.GetPairedSite().vcHost) valid credentials")
                    $RemotevCenter = Connect-VIServer $TempSRM.ExtensionData.GetPairedSite().vcHost -Credential $RemoteCredential -Port 443 -Protocol https -ErrorAction Stop
                    if ($RemotevCenter) {
                        Write-PScriboMessage "Connected to $((Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value)"
                        try {
                            $RemoteSRM = Connect-SrmServer -IgnoreCertificateErrors -Server $RemotevCenter -Credential $RemoteCredential -Port 443 -Protocol https -RemoteCredential $Credential
                            if ($RemoteSRM) {
                                Write-PScriboMessage "Succefully Connected to recovery site SRM with provided credentials"
                            }
                        }
                        catch {
                            Write-PScriboMessage -IsWarning  "Unable to connect to recovery site SRM Server"
                            Write-Error $_
                            throw
                        }
                    }
                }
                catch {
                    Write-PScriboMessage -IsWarning  "Unable to connect to recovery site vCenter Server: $($TempSRM.ExtensionData.GetPairedSite().vcHost)"
                    Write-Error $_
                    throw
                }
            }
        }
        catch {
            Write-Error $_
        }
        try {
            Write-PScriboMessage "Connecting to protected site SRM with updated credentials"
            $LocalSRM = Connect-SrmServer -IgnoreCertificateErrors -ErrorAction Stop -Port 443 -Protocol https -Credential $Credential -Server $LocalvCenter -RemoteCredential $RemoteCredential
            if ($LocalSRM) {
                Write-PScriboMessage "Reconnected to protected site SRM: $($LocalSRM.Name)"
            }
        } catch {
            Write-PScriboMessage -IsWarning  "Unable to connect to protected site SRM server"
            Write-Error "$($_) (Local SRM Connection)"
            throw
        }

        if ($LocalSRM) {
            Section -Style Heading1 "VMware Site Recovery Manager - $($LocalSRM.Name.split(".", 2).toUpper()[0])." {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "VMware Site Recovery Manager is a business continuity and disaster recovery solution that helps you plan, test, and run the recovery of virtual machines between a protected vCenter Server site and a recovery vCenter Server site. You can use Site Recovery Manager to implement different types of recovery from the protected site to the recovery site."
                    BlankLine
                }
                if ($InfoLevel.Protected -ge 1) {
                    Get-AbrSRMProtectedSiteInfo
                }
                if ($InfoLevel.Recovery -ge 1) {
                    Get-AbrSRMRecoverySiteInfo
                }
                if ($InfoLevel.Summary -ge 1) {
                    Get-AbrSRMSummaryInfo
                }
                if ($InfoLevel.InventoryMapping -ge 1) {
                    Section -Style Heading2 'Inventory Mapping Summary' {
                        if ($Options.ShowDefinitionInfo) {
                            Paragraph "When you install Site Recovery Manager you have to fo Inventory Mapping from Protected Site to Recovery Site. Inventory mappings provide default objects in the inventory of the recovery site for the recovered virtual machines to use when you run Test/Recovery. Inventory Mappings includes Network Mappings, Folder Mappings, Resource Mappings and Storage Policy Mappings. All of the Mappings are required for proper management and configuration of virtual machine at DR Site."
                            BlankLine
                        }
                        Paragraph "The following section provides a summary of the Inventory Mapping on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        BlankLine
                        Get-AbrSRMInventoryMapping
                    }
                }

                if ($InfoLevel.ProtectionGroup -ge 1) {
                    Get-AbrSRMProtectionGroupInfo
                }
                if ($InfoLevel.RecoveryPlan -ge 1) {
                    Get-AbrSRMRecoveryPlanInfo
                }
                if ($InfoLevel.Summary -ge 1) {
                    Get-AbrVRMSProtectionInfo
                }
            }

        }
	}
}
#end