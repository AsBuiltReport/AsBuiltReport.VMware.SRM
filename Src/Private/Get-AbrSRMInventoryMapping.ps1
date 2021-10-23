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
            $FolderMapping = $SRMServer.ExtensionData.InventoryMapping.GetFolderMappings()
            Section -Style Heading2 'Folder Mapping Summary' {
                Paragraph "The following section provides a summary of the Folder Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                if ($FolderMapping) {
                    $FolderHash = $Null
                    foreach ($FolderMap in $FolderMapping) {
                        Write-PscriboMessage "Discovered Folder Mapping information for $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalFolder = get-view $FolderMap.PrimaryObject | Select-Object -ExpandProperty Name
                        $RemoteFolder = get-view $FolderMap.SecondaryObject | Select-Object -ExpandProperty Name
                        $FolderHash = @{
                            $LocalFolder = $RemoteFolder
                        }
                        $inObj = [ordered] @{
                            "Local Folder" = $FolderHash.Keys
                            "Remote Folder" = $FolderHash.Values
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "Folder Mapping - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
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
        <#
        try {
            $NetworkMapping = $SRMServer.ExtensionData.InventoryMapping.GetFolderMappings()
            Section -Style Heading2 'Network Mapping Summary' {
                Paragraph "The following section provides a summary of the Folder Mapping on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                if ($FolderMapping) {
                    $FolderHash = $Null
                    foreach ($FolderMap in $FolderMapping) {
                        Write-PscriboMessage "Discovered Folder Mapping information for $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        $LocalFolder = get-view $FolderMap.PrimaryObject | Select-Object -ExpandProperty Name
                        $RemoteFolder = get-view $FolderMap.SecondaryObject | Select-Object -ExpandProperty Name
                        $FolderHash = @{
                            $LocalFolder = $RemoteFolder
                        }
                        $inObj = [ordered] @{
                            "Local Folder" = $FolderHash.Keys
                            "Remote Folder" = $FolderHash.Values
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "Folder Mapping - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
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
        }#>
    }
    end {}
}