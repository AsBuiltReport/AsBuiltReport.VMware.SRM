function Get-AbrSRMPlaceholderDatastore {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Placeholder Datastore information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PScriboMessage "Collecting Placeholder Datastore information."
    }

    process {
        $LocalPlaceholderMapping = $LocalSRM.ExtensionData.PlaceholderDatastoreManager.GetPlaceholderDatastores()
        $RemotePlaceholderMapping = $RemoteSRM.ExtensionData.PlaceholderDatastoreManager.GetPlaceholderDatastores()
        if (($LocalPlaceholderMapping) -or ($RemotePlaceholderMapping)) {
            Section -Style Heading2 'Placeholder Datastores' {
                $OutObj = @()
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "Placeholder datastores on the recovery site are used to store placeholder virtual machines."
                    BlankLine
                }
                if ($LocalPlaceholderMapping) {
                    foreach ($ObjMap in $LocalPlaceholderMapping) {
                        try {
                            if ($ObjMap) {
                                Write-PScriboMessage "Discovered Placeholder Datastore information for $($ObjMap.Name)."
                                $inObj = [ordered] @{
                                    'Site' = $($ProtectedSiteName)
                                    "Name"           = $ObjMap.Name
                                    "Host/Cluster"   = Switch (($ObjMap.VisibleTo.key).count) {
                                        0 { '--' }
                                        default { Get-View $ObjMap.VisibleTo.key -Server $LocalvCenter | Select-Object -ExpandProperty Name -Unique }
                                    }
                                    "Datastore Type" = $ObjMap.Type
                                    "Capacity"       = "$([math]::Round(($ObjMap.Capacity)/ 1GB, 2)) GB"
                                    "Free Space"     = "$([math]::Round(($ObjMap.FreeSpace)/ 1GB, 2)) GB"
                                    "Reserved Space" = "$([math]::Round(($ObjMap.ReservedSpace)/ 1GB, 2)) GB"
                                    "Fault"          = Switch ($ObjMap.Fault) {
                                        "" { 'None'; break }
                                        $Null { 'None'; break }
                                        default { $ObjMap.Fault }
                                    }
                                    "Status"         = Switch ($ObjMap.Status) {
                                        "green" { "OK" }
                                        "orange" { "Warning" }
                                        "red" { "Critical" }
                                        default { $ObjMap.Status }
                                    }
                                }
                                $OutObj += $inobj
                            }
                        }
                        catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
                if ($RemotePlaceholderMapping) {
                    foreach ($ObjMap in $RemotePlaceholderMapping) {
                        try {
                            if ($ObjMap) {
                                Write-PScriboMessage "Discovered Placeholder Datastore information for $($ObjMap.Name)."
                                $inObj = [ordered] @{
                                    'Site' = $($RecoverySiteName)
                                    "Name"           = $ObjMap.Name
                                    "Host/Cluster"   = Switch (($ObjMap.VisibleTo.key).count) {
                                        0 { '--' }
                                        default { Get-View $ObjMap.VisibleTo.key -Server $RemotevCenter | Select-Object -ExpandProperty Name -Unique }
                                    }
                                    "Datastore Type" = $ObjMap.Type
                                    "Capacity"       = "$([math]::Round(($ObjMap.Capacity)/ 1GB, 2)) GB"
                                    "Free Space"     = "$([math]::Round(($ObjMap.FreeSpace)/ 1GB, 2)) GB"
                                    "Reserved Space" = "$([math]::Round(($ObjMap.ReservedSpace)/ 1GB, 2)) GB"
                                    "Fault"          = Switch ($ObjMap.Fault) {
                                        "" { 'None'; break }
                                        $Null { 'None'; break }
                                        default { $ObjMap.Fault }
                                    }
                                    "Status"         = Switch ($ObjMap.Status) {
                                        "green" { "OK" }
                                        "orange" { "Warning" }
                                        "red" { "Critical" }
                                        default { $ObjMap.Status }
                                    }
                                }
                                $OutObj += $inobj
                            }
                        }
                        catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }

                $TableParams = @{
                    Name = "Placeholder Datastores"
                    #ColumnWidths = 50, 50
                    List = $true
                    Key = 'Site'
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                Table -Hashtable $OutObj @TableParams
            }
        }
    }

    end {}
}