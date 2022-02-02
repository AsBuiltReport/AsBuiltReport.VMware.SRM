function Get-AbrSRMInventoryMapping {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Inventory Mapping Summary information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.2
        Author:         Jonathan Colon
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
        Write-PScriboMessage "Inventory Mapping InfoLevel set at $($InfoLevel.InventoryMapping)."
        Write-PscriboMessage "Collecting SRM Inventory Mapping information."
    }

    process {
        try {
            $Mapping = $LocalSRM.ExtensionData.InventoryMapping.GetFolderMappings()
            Section -Style Heading3 'Folder Mappings' {
                $OutObj = @()
                if ($Mapping) {
                    foreach ($ObjMap in $Mapping) {
                        try {
                            $HashObj = $Null
                            Write-PscriboMessage "Discovered Folder Mapping information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                            $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                            $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
                            $HashObj = @{
                                $LocalObj = $RemoteObj
                            }
                            $inObj = [ordered] @{
                                "$($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)" = $HashObj.Keys
                                "$($LocalSRM.ExtensionData.GetPairedSite().Name)" = $HashObj.Values
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
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
                $OutObj = @()
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        try {
                            Write-PscriboMessage "Discovered Network Mapping information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                            $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                            $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
                            $HashObj = @{
                                $LocalObj = $RemoteObj
                            }
                            $inObj = [ordered] @{
                                "$($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)" = $HashObj.Keys
                                "$($LocalSRM.ExtensionData.GetPairedSite().Name)" = $HashObj.Values
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
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
                $OutObj = @()
                if ($Mapping) {
                    $HashObj = $Null
                    foreach ($ObjMap in $Mapping) {
                        try {
                            Write-PscriboMessage "Discovered Resources Mapping information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                            $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                            $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
                            $HashObj = @{
                                $LocalObj = $RemoteObj
                            }
                            $inObj = [ordered] @{
                                "$($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)" = Switch ($HashObj.Keys) {
                                    "Resources" {"Root Resource Pool"}
                                    default {$HashObj.Keys}
                                }
                                "$($LocalSRM.ExtensionData.GetPairedSite().Name)" = Switch ($HashObj.Values) {
                                    "Resources" {"Root Resource Pool"}
                                    default {$HashObj.Values}
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
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
                $LocalMapping = $LocalSRM.ExtensionData.PlaceholderDatastoreManager.GetPlaceholderDatastores()
                $RemoteMapping = $RemoteSRM.ExtensionData.PlaceholderDatastoreManager.GetPlaceholderDatastores()
                Section -Style Heading3 'Placeholder Datastore Mappings' {
                    if ($Options.ShowDefinitionInfo) {
                        Paragraph "For each protected virtual machine Site Recovery Manager creates a placeholder virtual machine at the recovery site. Placeholder virtual machines are contained in a datastore and registered with the vCenter Server at the recovery site. This datastore is called the placeholder datastore. Since placeholder virtual machines do not have virtual disks they consume a minimal amount of storage"
                        BlankLine
                    }
                    $OutObj = @()
                    if ($LocalMapping -or $RemoteMapping) {
                        foreach ($ObjMap in $LocalMapping) {
                            try {
                                if ($ObjMap) {
                                    Write-PscriboMessage "Discovered Placeholder Datastore Mapping information for $($ObjMap.Name)."
                                    $inObj = [ordered] @{
                                        "Name" = $ObjMap.Name
                                        "Datastore Type" = $ObjMap.Type
                                        "Capacity" = "$([math]::Round(($ObjMap.Capacity)/ 1GB, 2)) GB"
                                        "Free Space" = "$([math]::Round(($ObjMap.FreeSpace)/ 1GB, 2)) GB"
                                        "Reserved Space" = "$([math]::Round(($ObjMap.ReservedSpace)/ 1GB, 2)) GB"
                                        "Location" = Switch (($ObjMap.VisibleTo.key).count) {
                                            0 {"-"}
                                            default {ConvertTo-VIobject $ObjMap.VisibleTo.key}
                                        }
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
                                    $OutObj = [pscustomobject]$inobj

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
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        foreach ($ObjMap in $RemoteMapping) {
                            try {
                                if ($ObjMap) {
                                    Write-PscriboMessage "Discovered Placeholder Datastore Mapping information for $($ObjMap.Name)."
                                    $inObj = [ordered] @{
                                        "Name" = $ObjMap.Name
                                        "Datastore Type" = $ObjMap.Type
                                        "Capacity" = "$([math]::Round(($ObjMap.Capacity)/ 1GB, 2)) GB"
                                        "Free Space" = "$([math]::Round(($ObjMap.FreeSpace)/ 1GB, 2)) GB"
                                        "Reserved Space" = "$([math]::Round(($ObjMap.ReservedSpace)/ 1GB, 2)) GB"
                                        "Location" = Switch (($ObjMap.VisibleTo.key).count) {
                                            0 {"-"}
                                            default {ConvertTo-VIobject $ObjMap.VisibleTo.key}
                                        }
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
                                    $OutObj = [pscustomobject]$inobj

                                    if ($Healthcheck.InventoryMapping.Status) {
                                        $OutObj | Where-Object { $_.'Status' -ne 'OK'} | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Placeholder Datastore Mappings - $($LocalSRM.ExtensionData.GetPairedSite().Name)"
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
                    }
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