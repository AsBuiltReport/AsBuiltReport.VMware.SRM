function Get-AbrSRMStorageReplicationAdapter {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Storage Replication Adapter information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.2
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         @tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>

    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Collecting Storage Replication Adapter information."
    }

    process {
        try {
            $LocalSRA = $LocalSRM.ExtensionData.Storage.QueryStorageAdapters().fetchinfo()
            $RemoteSRA = $RemoteSRM.ExtensionData.Storage.QueryStorageAdapters().fetchinfo()
            if (($LocalSRA) -or ($RemoteSRA)) {
                Section -Style Heading2 'Storage Replication Adapters' {
                    if ($Options.ShowDefinitionInfo) {
                        Paragraph "The Storage Replication Adapter (SRA) is a storage vendor-specific plug-in for VMware Site Recovery Manager. The adapter enables communication between SRM and a storage controller. The adapter interacts with the storage controller to discover replicated datastores."
                        BlankLine
                    }
                    Paragraph "The following table provides information for the Storage Replication Adapters which have been configured at each site."
                    BlankLine

                    $OutObj = @()
                    if ($LocalSRA) {
                        Write-PScriboMessage "Collecting Storage Replication Adapter information for $($ProtectedSiteName)."
                        foreach ($ObjMap in $LocalSRA) {
                            $InObj = [ordered] @{
                                'Site' = $($ProtectedSiteName)
                                'Name' = $ObjMap.Name.Text
                                'Version' = $ObjMap.Version
                                'Vendor' = $ObjMap.Vendor.Text
                                'Install Location' = $ObjMap.InstallPath
                                'Vendor URL' = $ObjMap.HelpUrl
                            }
                            $OutObj += $inobj
                        }
                    }
                    if ($RemoteSRA) {
                        Write-PScriboMessage "Collecting Storage Replication Adapter information for $($RecoverySiteName)."
                        foreach ($ObjMap in $RemoteSRA) {
                            $InObj = [ordered] @{
                                'Site' = $($RecoverySiteName)
                                'Name' = $ObjMap.Name.Text
                                'Version' = $ObjMap.Version
                                'Vendor' = $ObjMap.Vendor.Text
                                'Install Location' = $ObjMap.InstallPath
                                'Vendor URL' = $ObjMap.HelpUrl
                            }
                            $OutObj += $inobj
                        }
                    }

                    $TableParams = @{
                        Name = "Storage Replication Adapters"
                        List = $true
                        Key = 'Site'
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    Table -Hashtable $OutObj @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}
}