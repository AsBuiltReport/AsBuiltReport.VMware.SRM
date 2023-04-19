function Get-AbrSRMProtectedSite {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Protected Site information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PScriboMessage "Collecting SRM Protected Site information."
    }

    process {
        $ProtectedSiteInfo = $LocalSRM.ExtensionData.GetLocalSiteInfo()
        if ($ProtectedSiteInfo) {
            Write-PScriboMessage "Discovered Protected Site $($ProtectedSiteName)."
            Section -Style Heading3 'Protected Site' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "In a typical Site Recovery Manager installation, the protected site provides business-critical datacenter services. The protected site can be any site where vCenter Server supports a critical business need."
                    BlankLine
                }
                Paragraph "The following table provides information for the protected site, $($ProtectedSiteName)."
                BlankLine

                $OutObj = @()
                $inObj = [ordered] @{
                    'Protected Site Name' = $ProtectedSiteName
                    'Protected Site ID' = $ProtectedSiteInfo.SiteUuid
                    'SRM Server Name' = $LocalSRM.Name
                    'SRM Server Version' = $LocalSRM.Version
                    'SRM Server Build' = $LocalSRM.Build
                    'vCenter Server Name' = ($ProtectedSiteInfo.VcUrl).Split('/')[2].Split(':')[0]
                    'Number of Protection Groups' = ($LocalSRM.ExtensionData.Protection.ListProtectionGroups()).count
                    'Connected' = ConvertTo-TextYN $LocalSRM.IsConnected
                }
                $OutObj += [pscustomobject]$inobj

                if ($Healthcheck.Protected.Status) {
                    $ReplicaObj | Where-Object { $_.'Connected' -eq 'No' } | Set-Style -Style Warning -Property 'Connected'
                }

                $TableParams = @{
                    Name = "Protected Site - $($ProtectedSiteName)"
                    List = $true
                    ColumnWidths = 40, 60
                }

                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                $OutObj | Table @TableParams
            }

            try {
                $LocalSRMFQDN = $LocalSRM.Name
                $LocalSRMHostName = ($LocalSRM.Name).Split(".")[0]
                if ($LocalSRMFQDN) {
                    $LocalSRMVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.HostName -match $LocalSRMFQDN }
                }
                if (-not $LocalSRMVM) {
                    $LocalSRMVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.VmName -match $LocalSRMHostName }
                }
                if ($LocalSRMVM) {
                    Section -Style Heading4 "SRM Server VM Configuration" {
                        Paragraph "The following table details the hardware inventory of the SRM protected site, $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        BlankLine
                        $OutObj = @()
                        Write-PScriboMessage "Collecting SRM Server VM configuration for $($LocalSRMVM.Name)."
                        $inObj = [ordered] @{
                            'VM Name' = $LocalSRMVM.Name
                            'Number of CPUs' = $LocalSRMVM.NumCpu
                            'Cores Per Socket' = $LocalSRMVM.CoresPerSocket
                            'Memory in GB' = $LocalSRMVM.MemoryGB
                            'Host' = $LocalSRMVM.VMHost
                            'OS Type' = Switch ($LocalSRMVM.GuestId) {
                                "other3xLinux64Guest" { 'Photon OS' }
                                default { $LocalSRMVM.GuestId }
                            }
                            'Provisioned Space GB' = "$([math]::Round(($LocalSRMVM.ProvisionedSpaceGB)))"
                            'Used Space GB' = "$([math]::Round(($LocalSRMVM.UsedSpaceGB)))"
                            'Datastores' = $LocalSRMVM.DatastoreIdList | ForEach-Object { Get-View $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name }
                        }
                        $OutObj += [pscustomobject]$inobj

                        $TableParams = @{
                            Name = "SRM Server VM Configuration - $($LocalSRMVM.Name)"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        } else {
            Write-PScriboMessage "Unable to collect SRM Protected Site information."
        }
    }
    end {}
}