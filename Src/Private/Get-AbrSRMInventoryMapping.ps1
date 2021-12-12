function Get-AbrSRMInventoryMapping {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Inventory Mapping Summary information.
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
        Write-PScriboMessage "Inventory Mapping InfoLevel set at $($InfoLevel.InventoryMapping)."
        Write-PscriboMessage "Collecting SRM Inventory Mapping information."
    }

    process {
        try {
            $Mapping = $LocalSRM.ExtensionData.InventoryMapping.GetFolderMappings()
            Section -Style Heading3 'Folder Mappings' {
                Paragraph "The following section provides a summary of the Folder Mapping on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                if ($Mapping) {
                    foreach ($ObjMap in $Mapping) {
                        $HashObj = $Null
                        Write-PscriboMessage "Discovered Folder Mapping information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                        $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
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
                    Name = "Folder Mappings - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
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
            $Mapping = $LocalSRM.ExtensionData.InventoryMapping.GetNetworkMappings()
            Section -Style Heading3 'Network Mappings' {
                Paragraph "The following section provides a summary of the Network Mapping on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        Write-PscriboMessage "Discovered Network Mapping information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                        $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
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
                    Name = "Network Mappings - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
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
            $Mapping = $LocalSRM.ExtensionData.InventoryMapping.GetResourcePoolMappings()
            Section -Style Heading3 'Resources Mappings' {
                Paragraph "The following section provides a summary of the Resources Mapping on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        Write-PscriboMessage "Discovered Resources Mapping information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                        $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
                        $HashObj = @{
                            $LocalObj = $RemoteObj
                        }
                        $inObj = [ordered] @{
                            "Local Resource" = Switch ($HashObj.Keys) {
                                "Resources" {"Root Resource Pool"}
                                default {$HashObj.Keys}
                            }
                            "Remote Resource" = Switch ($HashObj.Values) {
                                "Resources" {"Root Resource Pool"}
                                default {$HashObj.Values}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "Resources Mappings - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
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
            if ($RemotevCenter) {
                $Mapping = $LocalSRM.ExtensionData.PlaceholderDatastoreManager.GetPlaceholderDatastores()
                Section -Style Heading3 'Placeholder Datastore Mappings' {
                    if ($Options.ShowDefinitionInfo) {
                        Paragraph "For each protected virtual machine Site Recovery Manager creates a placeholder virtual machine at the recovery site. Placeholder virtual machines are contained in a datastore and registered with the vCenter Server at the recovery site. This datastore is called the placeholder datastore. Since placeholder virtual machines do not have virtual disks they consume a minimal amount of storage"
                        BlankLine
                    }
                    Paragraph "The following section provides a summary of the Placeholder Datastore Mapping on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                    BlankLine
                    $OutObj = @()
                    if ($Mapping) {
                        foreach ($ObjMap in $Mapping) {
                            #//Todo "How the fuck i can extract remote PlaceHolder Datastore Info"
                            Write-PscriboMessage "Discovered Placeholder Datastore Mapping information for $($ObjMap.Name) on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                            $inObj = [ordered] @{
                                "Name" = $ObjMap.Name
                                "Datastore Type" = $ObjMap.Type
                                "Capacity" = "$([math]::Round(($ObjMap.Capacity)/ 1GB, 2)) GB"
                                "Free Space" = "$([math]::Round(($ObjMap.FreeSpace)/ 1GB, 2)) GB"
                                "Reserved Space" = "$([math]::Round(($ObjMap.ReservedSpace)/ 1GB, 2)) GB"
                                "Location" = ConvertTo-VIobject $ObjMap.VisibleTo.key
                                "Fault" = Switch ($ObjMap.Fault) {
                                    "" {"-"; break}
                                    $Null {"-"; break}
                                    default {$ObjMap.Fault}
                                }
                                "Status" = Switch ($ObjMap.Status) {
                                    "green" {"OK"}
                                    "orange" {"Warning"}
                                    "red" {"Critical"}
                                    default {$ObjMap.Status}
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                    }

                    if ($Healthcheck.InventoryMapping.Status) {
                        $OutObj | Where-Object { $_.'Status' -ne 'OK'} | Set-Style -Style Warning -Property 'Status'
                    }

                    $TableParams = @{
                        Name = "Placeholder Datastore Mappings - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
                        List = $true
                        ColumnWidths = 50, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
            else {Write-PscriboMessage -IsWarning "No Recovery Site vCenter connection has been detected. Deactivating placeholder datastore mappings section"}
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}