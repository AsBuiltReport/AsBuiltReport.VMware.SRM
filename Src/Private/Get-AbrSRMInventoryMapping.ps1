function Get-AbrSRMInventoryMapping {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Inventory Mapping Summary information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PScriboMessage "Collecting SRM Inventory Mapping information."
    }

    process {
        $FolderMappings = $LocalSRM.ExtensionData.InventoryMapping.GetFolderMappings()
        $ResPoolMappings = $LocalSRM.ExtensionData.InventoryMapping.GetResourcePoolMappings()
        $NetworkMappings = $LocalSRM.ExtensionData.InventoryMapping.GetNetworkMappings()
        $TestNetworkMappings = $LocalSRM.ExtensionData.InventoryMapping.GetTestNetworkMappings()

        if (($FolderMappings) -or ($NetworkMappings) -or ($ResPoolMappings)) {
            Section -Style Heading2 'Inventory Mappings' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "When you install Site Recovery Manager you have to fo Inventory Mapping from Protected Site to Recovery Site. Inventory mappings provide default objects in the inventory of the recovery site for the recovered virtual machines to use when you run Test/Recovery. Inventory Mappings includes Network Mappings, Folder Mappings, Resource Mappings and Storage Policy Mappings. All of the Mappings are required for proper management and configuration of virtual machine at DR Site."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the inventory mappings for the protected site, $($ProtectedSiteName)."
                BlankLine

                #region Collect Folder Mapping information
                if ($FolderMappings) {
                    Write-PScriboMessage "Discovered Folder Mapping information for $($ProtectedSiteName)."
                    Section -Style Heading3 'Folder Mappings' {
                        $OutObj = @()
                        foreach ($ObjMap in $FolderMappings) {
                            try {
                                $HashObj = $Null
                                $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                                $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
                                $HashObj = @{
                                    $LocalObj = $RemoteObj
                                }
                                $inObj = [ordered] @{
                                    "$($ProtectedSiteName)" = $HashObj.Keys
                                    "$($RecoverySiteName)" = $HashObj.Values
                                }
                                $OutObj += [pscustomobject]$inobj
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Folder Mappings - $($ProtectedSiteName)"
                            List = $false
                            ColumnWidths = 50, 50
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }

                        $OutObj | Table @TableParams
                    }
                }
                #endregion Collect Folder Mapping information

                #region Collect Network Mapping information
                if ($NetworkMappings) {
                    Write-PScriboMessage "Discovered Network Mapping information for $($ProtectedSiteName)."
                    Section -Style Heading3 'Network Mappings' {
                        $OutObj = @()
                        foreach ($ObjMap in $NetworkMappings) {
                            $inObj = [Ordered]@{
                                'Protected Network' = ConvertTo-VIobject $ObjMap.PrimaryObject
                                'Recovery Network' = ConvertTo-VIobject $ObjMap.SecondaryObject
                                'Test Network' = & {
                                    if ($TestNetworkMappings | Where-Object {$_.Key -eq $ObjMap.SecondaryObject}) {
                                        ConvertTo-VIobject (($TestNetworkMappings | Where-Object {$_.Key -eq $ObjMap.SecondaryObject}).TestNetwork)
                                    } else {
                                        'Isolated network (auto created)'
                                    }
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }

                        $TableParams = @{
                            Name = "Network Mappings - $($ProtectedSiteName)"
                            List = $false
                            ColumnWidths = 33, 33, 34
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }

                        $OutObj | Sort-Object 'Protected Network' | Table @TableParams
                    }
                }
                #endregion Collect Network Mapping information

                #region Collect Resource Pool Mapping information
                if ($ResPoolMappings) {
                    Write-PScriboMessage "Discovered Resources Mapping information for $($ProtectedSiteName)."
                    Section -Style Heading3 'Resources Mappings' {
                        $OutObj = @()
                        $HashObj = $Null
                        foreach ($ObjMap in $ResPoolMappings) {
                            try {
                                $LocalObj = ConvertTo-VIobject $ObjMap.PrimaryObject
                                $RemoteObj = ConvertTo-VIobject $ObjMap.SecondaryObject
                                $HashObj = @{
                                    $LocalObj = $RemoteObj
                                }
                                $inObj = [ordered] @{
                                    "$($ProtectedSiteName)" = Switch ($HashObj.Keys) {
                                        "Resources" { "Root Resource Pool" }
                                        default { $HashObj.Keys }
                                    }
                                    "$($RecoverySiteName)" = Switch ($HashObj.Values) {
                                        "Resources" { "Root Resource Pool" }
                                        default { $HashObj.Values }
                                    }
                                }
                                $OutObj += [pscustomobject]$inobj
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Resources Mappings - $($ProtectedSiteName)"
                            List = $false
                            ColumnWidths = 50, 50
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }

                        $OutObj | Table @TableParams
                    }
                }
                #endregion Collect Resource Pool Mapping information

                #region Placeholder Datastores
                    Get-AbrSRMPlaceholderDatastore
                #endregion Placeholder Datastores
            }
        }
    }
    end {}
}