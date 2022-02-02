function Get-AbrSRMProtectedSiteInfo {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Protected Site information.
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

    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Protected Site InfoLevel set at $($InfoLevel.Protected)."
        Write-PscriboMessage "Collecting SRM Protected Site information."
    }

    process {
        try {
            $ProtectedSiteInfo = $LocalSRM.ExtensionData.GetLocalSiteInfo()
            Section -Style Heading2 'Protected Site' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "In a typical Site Recovery Manager installation, the protected site provides business-critical datacenter services. The protected site can be any site where vCenter Server supports a critical business need."
                    BlankLine
                }
                Paragraph "The following table details information of the Protected Site $($ProtectedSiteInfo.SiteName)."
                BlankLine
                $OutObj = @()
                if ($ProtectedSiteInfo) {
                    Write-PscriboMessage "Discovered Protected Site $($ProtectedSiteInfo.SiteName)."
                    $inObj = [ordered] @{
                        'Server Name' = $LocalSRM.Name
                        'Protected Site Name' = $ProtectedSiteInfo.SiteName
                        'Protected Site ID' = $ProtectedSiteInfo.SiteUuid
                        'Solution User' = $LocalSRM.ExtensionData.GetSolutionUserInfo().Username
                        'SRM Version' = $LocalSRM.Version
                        'SRM Build' = $LocalSRM.Build
                        'vCenter URL' = $ProtectedSiteInfo.VcUrl
                        'Lookup URL' = $ProtectedSiteInfo.LkpUrl
                        'Protection Group Count' = ($LocalSRM.ExtensionData.Protection.ListProtectionGroups()).count
                        'Connected' = ConvertTo-TextYN $LocalSRM.IsConnected
                    }
                    $OutObj += [pscustomobject]$inobj
                }

                if ($Healthcheck.Protected.Status) {
                    $ReplicaObj | Where-Object { $_.'Connected' -eq 'No'} | Set-Style -Style Warning -Property 'Connected'
                }

                $TableParams = @{
                    Name = "Protected Site Information - $($ProtectedSiteInfo.SiteName)"
                    List = $true
                    ColumnWidths = 30, 70
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                try {
                    $LocalSRMFQDM = $LocalSRM.Name
                    $LocalSRMHostName = $LocalSRMFQDM.Split(".")[0]
                    if ($LocalSRMFQDM) {
                        $LocalSRMVM = Get-VM * -Server $LocalvCenter | where-object {$_.Guest.HostName -match $LocalSRMFQDM}
                    }
                    elseif (!$LocalSRMVM) {
                        $LocalSRMVM = Get-VM * -Server $LocalvCenter | where-object {$_.Guest.VmName -match $LocalSRMHostName}
                    }
                    if ($LocalSRMVM) {
                        Section -Style Heading4 "SRM Server VM Properties" {
                            Paragraph "The following table details the hardware inventory of the Protected Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                            BlankLine
                            $OutObj = @()
                            Write-PscriboMessage "Discovered SRM VM Properties $($LocalSRMVM.Name)."
                            $inObj = [ordered] @{
                                'VM Name' = $LocalSRMVM.Name
                                'Number of CPUs' = $LocalSRMVM.NumCpu
                                'Cores Per Socket' = $LocalSRMVM.CoresPerSocket
                                'Memory in GB' = $LocalSRMVM.MemoryGB
                                'Host' = $LocalSRMVM.VMHost
                                'Guest Id' = $LocalSRMVM.GuestId
                                'Provisioned Space GB' = "$([math]::Round(($LocalSRMVM.ProvisionedSpaceGB)))"
                                'Used Space GB' = "$([math]::Round(($LocalSRMVM.UsedSpaceGB)))"
                                'Datastores' = $LocalSRMVM.DatastoreIdList | ForEach-Object {get-view $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name}
                            }
                            $OutObj += [pscustomobject]$inobj

                            $TableParams = @{
                                Name = "SRM VM Properties - $($LocalSRMVM.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}