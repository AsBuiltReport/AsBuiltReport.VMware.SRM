function Get-AbrSRMNetworkMapping {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Network Mapping information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.6
        Author:         Jonathan Colon & Tim Carman
        Twitter:        @jcolonfzenpr / @tpcarman
        Github:         @rebelinux / @tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>

    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Collecting Network Mapping information."
    }

    process {
        $LocalNetworkMappings = $LocalSRM.ExtensionData.InventoryMapping.GetNetworkMappings()
        $LocalTestNetworkMappings = $LocalSRM.ExtensionData.InventoryMapping.GetTestNetworkMappings()
        $RemoteNetworkMappings = $RemoteSRM.ExtensionData.InventoryMapping.GetNetworkMappings()
        $RemoteTestNetworkMappings = $RemoteSRM.ExtensionData.InventoryMapping.GetTestNetworkMappings()
        if (($LocalNetworkMappings) -or ($RemoteNetworkMappings)) {
            Section -Style Heading2 'Network Mappings' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "Network mappings allow you to specify how Site Recovery Manager maps virtual machine networks on the protected site to virtual machine networks on the recovery site."
                    BlankLine
                }

                if ($LocalNetworkMappings) {
                    Section -Style NOTOCHeading3 -ExcludeFromTOC $($ProtectedSiteName) {
                        $OutObj = @()
                        foreach ($ObjMap in $LocalNetworkMappings) {
                            $inObj = [Ordered]@{
                                'Protected Network' = Get-View $ObjMap.PrimaryObject -Server $LocalvCenter | Select-Object -ExpandProperty Name -Unique
                                'Recovery Network' = Get-View $ObjMap.SecondaryObject -Server $RemotevCenter | Select-Object -ExpandProperty Name -Unique
                                'Test Network' = & {
                                    if ($LocalTestNetworkMappings | Where-Object { $_.Key -eq $ObjMap.SecondaryObject }) {
                                        Get-View (($LocalTestNetworkMappings | Where-Object { $_.Key -eq $ObjMap.SecondaryObject }).TestNetwork) -Server $LocalvCenter
                                    } else {
                                        'Isolated network (auto created)'
                                    }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
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

                if ($RemoteNetworkMappings) {
                    Section -Style NOTOCHeading3 -ExcludeFromTOC $($RecoverySiteName) {
                        $OutObj = @()
                        foreach ($ObjMap in $RemoteNetworkMappings) {
                            $inObj = [Ordered]@{
                                'Protected Network' = Get-View $ObjMap.PrimaryObject -Server $RemotevCenter | Select-Object -ExpandProperty Name -Unique
                                'Recovery Network' = Get-View $ObjMap.SecondaryObject -Server $LocalvCenter | Select-Object -ExpandProperty Name -Unique
                                'Test Network' = & {
                                    if ($RemoteTestNetworkMappings | Where-Object { $_.Key -eq $ObjMap.SecondaryObject }) {
                                        Get-View (($RemoteTestNetworkMappings | Where-Object { $_.Key -eq $ObjMap.SecondaryObject }).TestNetwork) -Server $RemotevCenter
                                    } else {
                                        'Isolated network (auto created)'
                                    }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }

                        $TableParams = @{
                            Name = "Network Mappings - $($RecoverySiteName)"
                            List = $false
                            ColumnWidths = 33, 33, 34
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }

                        $OutObj | Sort-Object 'Protected Network' | Table @TableParams
                    }
                }
            }
        }
    }

    end {}
}