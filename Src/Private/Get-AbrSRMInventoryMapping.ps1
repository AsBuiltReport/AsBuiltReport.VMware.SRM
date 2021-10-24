function Get-AbrSRMInventoryMapping {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Inventory Mapping Summary information.
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        Write-PScriboMessage "Inventory Mapping InfoLevel set at $($InfoLevel.InventoryMapping)."
        Write-PscriboMessage "Collecting SRM Inventory Mapping information."
    }

    process {
        try {
            $Mapping = $SRMServer.ExtensionData.InventoryMapping.GetFolderMappings()
            Section -Style Heading2 'Folder Mappings Summary' {
                Paragraph "The following section provides a summary of the Folder Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        Write-PscriboMessage "Discovered Folder Mapping information for $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalObj = get-view $ObjMap.PrimaryObject | Select-Object -ExpandProperty Name
                        $RemoteObj = get-view $ObjMap.SecondaryObject | Select-Object -ExpandProperty Name
                        $HashObj = @{
                            $LocalObj = $RemoteObj
                        }
                        $inObj = [ordered] @{
                            "Local Folder" = $HashObj.Keys
                            "Remote Folder" = $HashObj.Values
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "Folder Mappings - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
        try {
            $Mapping = $SRMServer.ExtensionData.InventoryMapping.GetNetworkMappings()
            Section -Style Heading2 'Network Mappings Summary' {
                Paragraph "The following section provides a summary of the Network Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        Write-PscriboMessage "Discovered Network Mapping information for $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalObj = get-view $ObjMap.PrimaryObject | Select-Object -ExpandProperty Name
                        $RemoteObj = get-view $ObjMap.SecondaryObject | Select-Object -ExpandProperty Name
                        $HashObj = @{
                            $LocalObj = $RemoteObj
                        }
                        $inObj = [ordered] @{
                            "Local Network" = $HashObj.Keys
                            "Remote Network" = $HashObj.Values
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "Network Mappings - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
        try {
            $Mapping = $SRMServer.ExtensionData.InventoryMapping.GetResourcePoolMappings()
            Section -Style Heading2 'Resources Mappings Summary' {
                Paragraph "The following section provides a summary of the Resources Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        Write-PscriboMessage "Discovered Resources Mapping information for $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalObj = get-view $ObjMap.PrimaryObject | Select-Object -ExpandProperty Name
                        $RemoteObj = get-view $ObjMap.SecondaryObject | Select-Object -ExpandProperty Name
                        $HashObj = @{
                            $LocalObj = $RemoteObj
                        }
                        $inObj = [ordered] @{
                            "Local Resource" = $HashObj.Keys
                            "Remote Resource" = $HashObj.Values
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "Resources Mappings - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
        try {
            $Mapping = $SRMServer.ExtensionData.PlaceholderDatastoreManager.GetPlaceholderDatastores()
            Section -Style Heading2 'Placeholder Datastore Mappings Summary' {
                Paragraph 'For each protected virtual machine Site Recovery Manager creates a placeholder virtual machine at the recovery site. Placeholder virtual machines are contained in a datastore and registered with the vCenter Server at the recovery site. This datastore is called the “placeholder datastore”. Since placeholder virtual machines do not have virtual disks they consume a minimal amount of storage'
                Paragraph "The following section provides a summary of the Placeholder Datastore Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                if ($Mapping) {
                    foreach ($ObjMap in $Mapping) {
                        #//Todo "How the fuck i can extract remote PlaceHolder Datastore Info"
                        Write-PscriboMessage "Discovered Placeholder Datastore Mapping information for $($ObjMap.Name) on $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $inObj = [ordered] @{
                            "Name" = $ObjMap.Name
                            "Datastore Type" = $ObjMap.Type
                            "Capacity" = "$([math]::Round(($ObjMap.Capacity)/ 1GB, 2)) GB"
                            "Free Space" = "$([math]::Round(($ObjMap.FreeSpace)/ 1GB, 2)) GB"
                            "Reserved Space" = "$([math]::Round(($ObjMap.ReservedSpace)/ 1GB, 2)) GB"
                            "Location" = get-view $ObjMap.VisibleTo.key | Select-Object -ExpandProperty Name
                            "Fault" = ConvertTo-EmptyToFiller $ObjMap.Fault
                            "Status" = SWitch ($ObjMap.Status) {
                                "green" {"Ok"}
                                "orange" {"Warning"}
                                "red" {"Critical"}
                                default {$ObjMap.Status}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }

                if ($Healthcheck.InventoryMapping.Status) {
                    $ReplicaObj | Where-Object { $_.'Status' -ne 'OK'} | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Placeholder Datastore Mappings - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
                    List = $true
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}