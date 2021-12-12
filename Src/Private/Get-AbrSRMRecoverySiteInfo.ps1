function Get-AbrSRMRecoverySiteInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Recovery Site information.
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Recovery Site InfoLevel set at $($InfoLevel.Recovery)."
        Write-PscriboMessage "Collecting SRM Recovery Site information."
    }

    process {
        try {
            $RecoverySiteInfo = $LocalSRM.ExtensionData.GetPairedSite()
            Section -Style Heading2 'Recovery Site' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "In a typical Site Recovery Manager installation, the recovery site is an alternative infrastructure to which Site Recovery Manager can migrate services. The recovery site can be located thousands of miles away from the protected site. Conversely, the recovery site can be in the same room as a way of establishing redundancy. The recovery site is usually located in a facility that is unlikely to be affected by environmental, infrastructure, or other disturbances that affect the protected site."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the Recovery Site $($RecoverySiteInfo.Name)."
                BlankLine
                $OutObj = @()
                if ($RecoverySiteInfo) {
                    $RemoteSRM = "Unknown"
                    if ($RemotevCenter) {
                        $extensionmanager = get-view extensionmanager -Server $RemotevCenter
                        $extension = $extensionmanager.extensionlist | where-object { $_.key -eq "com.vmware.vcDR" }
                        if($extension.count -eq 1){
                            $RemoteSRM = $extension.server.url.split("/")[2].split(":")[0]
                        } else {$RemoteSRM = "Unknown"}
                    }
                    Write-PscriboMessage "Discovered Recovery Site $($RecoverySiteInfo.Name)."
                    $inObj = [ordered] @{
                        'Recovery Server Name' = $RemoteSRM
                        'Recovery Site Name' = $RecoverySiteInfo.Name
                        'Recovery Site ID' = $RecoverySiteInfo.Uuid
                        'Solution User' = $LocalSRM.ExtensionData.GetPairedSiteSolutionUserInfo().Username
                        'vCenter Host' = $RecoverySiteInfo.VcHost
                        'vCenter URL' = $RecoverySiteInfo.VcUrl
                        'Lookup URL' = $RecoverySiteInfo.LkpUrl
                        'Connected' = ConvertTo-TextYN $RecoverySiteInfo.Connected
                    }
                    $OutObj += [pscustomobject]$inobj
                }

                if ($Healthcheck.Recovery.Status) {
                    $ReplicaObj | Where-Object { $_.'Connected' -eq 'No'} | Set-Style -Style Warning -Property 'Connected'
                }

                $TableParams = @{
                    Name = "Recovery Site Information - $($RecoverySiteInfo.Name)"
                    List = $true
                    ColumnWidths = 30, 70
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                try {
                    if ($RemotevCenter) {
                        $extensionmanager = get-view extensionmanager -Server $RemotevCenter
                        $extension = $extensionmanager.extensionlist | where-object { $_.key -eq "com.vmware.vcDR" }
                        if($extension.count -eq 1){
                            $RemoteSRM = $extension.server.url.split("/")[2].split(":")[0]
                        }
                        $RemoteSRMFQDM = $RemoteSRM
                        $RemoteSRMHostName = $RemoteSRMFQDM.Split(".")[0]
                        if ($RemoteSRMFQDM) {
                            $RemoteSRMVM = Get-VM * | where-object {$_.Guest.HostName -match $RemoteSRMFQDM}
                        }
                        elseif (!$RemoteSRMVM) {
                            $RemoteSRMVM = Get-VM * | where-object {$_.Guest.VmName -match $RemoteSRMHostName}
                        }
                        if ($RemoteSRMVM) {
                            Section -Style Heading4 "SRM Server VM Properties" {
                                Paragraph "The following section provides the hardware properties of the Protected Site $($RecoverySiteInfo.Name)."
                                BlankLine
                                $OutObj = @()
                                Write-PscriboMessage "Discovered SRM VM Properties $($RemoteSRMVM.Name)."
                                $inObj = [ordered] @{
                                    'VM Name' = $RemoteSRMVM.Name
                                    'Number of CPUs' = $RemoteSRMVM.NumCpu
                                    'Cores Per Socket' = $RemoteSRMVM.CoresPerSocket
                                    'Memory in GB' = $RemoteSRMVM.MemoryGB
                                    'Host' = $RemoteSRMVM.VMHost
                                    'Guest Id' = $RemoteSRMVM.GuestId
                                    'Provisioned Space GB' = "$([math]::Round(($RemoteSRMVM.ProvisionedSpaceGB)))"
                                    'Used Space GB' = "$([math]::Round(($RemoteSRMVM.UsedSpaceGB)))"
                                    'Datastores' = $RemoteSRMVM.DatastoreIdList | ForEach-Object {get-view $_ | Select-Object -ExpandProperty Name}
                                }
                                $OutObj += [pscustomobject]$inobj

                                $TableParams = @{
                                    Name = "SRM VM Properties - $($RemoteSRMVM.Name)"
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