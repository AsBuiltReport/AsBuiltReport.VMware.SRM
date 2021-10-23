function Invoke-AsBuiltReport.VMware.SRM {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of VMware SRM in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
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

	# Update/rename the $System variable and build out your code within the ForEach loop. The ForEach loop enables AsBuiltReport to generate an as built configuration against multiple defined targets.

    #region foreach loop
    #---------------------------------------------------------------------------------------------#
    #                                 Connection Section                                          #
    #---------------------------------------------------------------------------------------------#
    foreach ($VIServer in $Target) {
        try {
            $LocalvCenter = Connect-VIServer $VIServer -Credential $Credential -ErrorAction Stop
            $SRMServer = Connect-SrmServer -IgnoreCertificateErrors -ErrorAction Stop -Port 443 -Protocol https -Credential $Credential -RemoteCredential $Credential -Server $LocalvCenter
            $RemotevCenter = Connect-VIServer $SRMServer.ExtensionData.GetPairedSite().vcHost  -Credential $Credential -ErrorAction Stop
        } catch {
            Write-Error $_
        }

        try {
            $RemotevCenter = Connect-VIServer $SRMServer.ExtensionData.GetPairedSite().vcHost  -Credential $Credential -ErrorAction Stop
            if ($Null -eq $RemotevCenter) {
                try {
                    $RemotevCenter = Connect-VIServer $SRMServer.ExtensionData.GetPairedSite().vcHost  -Credential (Get-Credential) -ErrorAction Stop
                }
                catch {
                    Write-PScriboMessage -IsWarning "Unable to connect to Remote vCenter Server" -ErrorAction Continue
                    Write-Error $_
                }
            }
        } catch {
            Write-Error $_
        }

        if ($SRMServer) {
            Section -Style Heading1 "VMware Site Recovery Manager - $($SRMServer.Name.split(".", 2).toUpper()[0])." {
                Paragraph "VMware Site Recovery Manager is a business continuity and disaster recovery solution that helps you plan, test, and run the recovery of virtual machines between a protected vCenter Server site and a recovery vCenter Server site. You can use Site Recovery Manager to implement different types of recovery from the protected site to the recovery site."
                BlankLine
                if ($InfoLevel.Summary -ge 1) {
                    Get-AbrSRMSummaryInfo
                }
                if ($InfoLevel.InventoryMapping -ge 1) {
                    Section -Style Heading2 'Inventory Mapping Summary' {
                        Paragraph "When you install Site Recovery Manager you have to fo Inventory Mapping from Protected Site to Recovery Site. Inventory mappings provide default objects in the inventory of the recovery site for the recovered virtual machines to use when you run Test/Recovery. Inventory Mappings includes Network Mappings, Folder Mappings, Resource Mappings and Storage Policy Mappings. All of the Mappings are required for proper management and configuration of virtual machine at DR Site."
                        Paragraph "The following section provides a summary of the Inventory Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        BlankLine
                        Get-AbrSRMInventoryMapping
                    }
                }
                if ($InfoLevel.Protected -ge 1) {
                    Get-AbrSRMProtectedSiteInfo
                }
                if ($InfoLevel.Recovery -ge 1) {
                    Get-AbrSRMRecoverySiteInfo
                }
                if ($InfoLevel.ProtectionGroup -ge 1) {
                    Get-AbrSRMProtectionGroupInfo
                }
            }

        }
	}
	#endregion foreach loop
}
