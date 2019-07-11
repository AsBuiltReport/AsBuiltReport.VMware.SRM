function Invoke-AsBuiltReport.VMware.SRM {
    <#
    .SYNOPSIS  
        PowerShell script to document the configuration of VMware Site Recovery Manager infrastucture in Word/HTML/XML/Text formats
    .DESCRIPTION
        Documents the configuration of VMware Site Recovery Manager infrastucture in Word/HTML/XML/Text formats using PScribo.
    .NOTES
        Version:        0.0.1
        Author:         Matthew Allford
        Twitter:        @mattallford
        Github:         mattallford
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
                        
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>

    param (
        [String[]] $Target,
        [PSCredential] $Credential,
        [String]$StylePath
    )

    # Import JSON Configuration for Options and InfoLevel
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # If custom style not set, use default style
    if (!$StylePath) {
        & "$PSScriptRoot\..\..\AsBuiltReport.VMware.SRM.Style.ps1"
    }

    foreach ($VIServer in $Target) {
        #Connect to the SRM Server
        try {
            $vCenter = Connect-VIServer $VIServer -Credential $Credential -ErrorAction Stop
            $SRM = Connect-SrmServer -IgnoreCertificateErrors -ErrorAction Stop
        } catch {
            Write-Error $_
        }

        if ($SRM) {
            $LocalSiteInfo = $SRM.ExtensionData.GetLocalSiteInfo()
            $LocalSiteSolutionUser = $SRM.ExtensionData.GetSolutionUserInfo()
            $PairedSiteInfo = $SRM.ExtensionData.GetPairedSite()
            $PairedSiteSolutionUser = $SRM.ExtensionData.GetPairedSiteSolutionUserInfo()
            $ProtectionGroups = $SRM.ExtensionData.Protection.ListProtectionGroups()
            $RecoveryPlans = $SRM.ExtensionData.Recovery.ListPlans()

            Section -Style Heading1 $SRM.Name {

                Section -Style Heading2 'System Summary' {
                    Paragraph "The following section provides a summary of the system $($SRM.Name)."
                    BlankLine
                    #Provide a summary of the SRM Server
                    $SRMSummary = [PSCustomObject] @{
                        'Server Name' = $SRM.Name
                        'Site Name' = $LocalSiteInfo.SiteName
                        'Site ID' = $LocalSiteInfo.SiteUuid
                        'Solution User' = $LocalSiteSolutionUser.Username
                        'SRM Version' = $SRM.Version
                        'SRM Build' = $SRM.Build
                        'vCenter URL' = $LocalSiteInfo.VcUrl
                        'Lookup URL' = $LocalSiteInfo.LkpUrl
                        'Protection Group #' = $ProtectionGroups.count
                    }
                    $SRMSummary | Table -Name 'SRM Summary' -List -ColumnWidths 50, 50
                }#End Section Heading2 System Summary

                Section -Style Heading2 'Paired Site' {
                    Paragraph "The following section provides a summary of the paired site for $($SRM.Name)."
                    BlankLine
                    # Provide a summary of the paired SRM Site
                    $SRMPairedSite = [PSCustomObject] @{
                        'Paired Site Name' = $PairedSiteInfo.Name
                        'Paired Site ID' = $PairedSiteInfo.Uuid
                        'Paired Site Solution User' = $PairedSiteSolutionUser.Username
                        'Paired Site vCenter Host' = $PairedSiteInfo.VcHost
                        'Paired Site vCenter URL' = $PairedSiteInfo.VcUrl
                        'Paired Site Lookup URL' = $PairedSiteInfo.LkpUrl
                        'Paired Site Connected' = $PairedSiteInfo.Connected
                    }
                    $SRMPairedSite | Table -Name 'SRM Paired Site Summary' -List -ColumnWidths 50, 50
                } #End Section Heading2 Paired Site

                Section -Style Heading2 'Protection Groups' {
                    Paragraph "The Following section provides a summary of the Protection Groups configured under $($SRM.Name)"
                    BlankLine
                    # Provide a summary of protection groups
                    foreach ($ProtectionGroup in $ProtectionGroups) {
                        #Filter protection groups that this SRM instance does not own
                        if ($ProtectionGroup.GetProtectionState() -ne "Shadowing") {
                            Section -Style Heading3 $ProtectionGroup.GetInfo().Name {
                                if ($ProtectionGroup.ListProtectedDatastores()) {
                                    $ProtectedDatastores = (Get-View $ProtectionGroup.ListProtectedDatastores().moref | Select-Object Name)
                                }

                                if ($ProtectionGroup.ListProtectedVMs()) {
                                    $ProtectedVMs = (Get-View $ProtectionGroup.ListProtectedVMs().vm.moref | Select-Object Name)
                                }

                                $ProtectionGroupInfo = $ProtectionGroup.GetInfo()

                                $ProtectionGroupConfig = [PSCustomObject] @{
                                    'Name' = $ProtectionGroupInfo.Name
                                    'Description' = $ProtectionGroupInfo.Description
                                    'Type' = $ProtectionGroupInfo.Type
                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                    'Protected Datastores' = ($ProtectedDatastores.Name | Sort-Object) -join ', '
                                    'Protected VMs' = ($ProtectedVMs.Name | Sort-Object) -join ', '
                                }
                                $ProtectionGroupConfig | Table -Name "Protection Group Config" -List -ColumnWidths 50, 50
                            }
                        }
                    }
                }#End Section Heading2 Protection Groups

                Section -Style Heading2 'Recovery Plans' {
                    Paragraph "The Following section provides a summary of the Recovery Plans configured under $($SRM.Name)"
                    BlankLine
                    foreach ($RecoveryPlan in $RecoveryPlans) {
                        $RecoveryPlanInfo = $RecoveryPlan.GetInfo()
                        Section -Style Heading3 $RecoveryPlanInfo.Name {
                            $PlanProtectionGroups = foreach ($PlanProtectionGroup in $RecoveryPlan.getinfo().ProtectionGroups) {
                                $PlanProtectionGroup.GetInfo().Name
                            }
                        
                            $RecoveryPlanConfig = [PSCustomObject] @{
                                'Plan Name' = $RecoveryPlanInfo.name
                                'Description' = $RecoveryPlanInfo.Description
                                'State' = $RecoveryPlanInfo.State
                                'Protection Groups' = ($PlanProtectionGroups | Sort-Object) -join ', '
                            }
                            $RecoveryPlanConfig | Table -Name "Recovery Plan Config" -List -ColumnWidths 25, 75
                        }#End Section Heading3
                    }
                }#End Section Heading2 Recovery Plans
            } #End Section Heading1 $SRM.Name
        } #End if SRM
        Disconnect-VIServer -Server $VIServer -Confirm:$false
        Disconnect-SrmServer -Server $SRM.Name -Confirm:$false
    } #End foreach SRMServer in Target

} #End function Invoke-AsBuiltReport.VMware.SRM