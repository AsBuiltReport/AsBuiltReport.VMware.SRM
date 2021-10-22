function Get-AbrSRMSummaryInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Summary information.
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
        Write-PScriboMessage "Summary InfoLevel set at $($InfoLevel.Summary)."
        Write-PscriboMessage "Collecting SRM Summary information."
    }

    process {
        try {
            $LicenseInfo = $SRMServer.ExtensionData.GetLicenseInfo()
            Section -Style Heading2 'License Summary' {
                Paragraph "The following section provides a summary of the License Feature on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                if ($LicenseInfo) {
                    Write-PscriboMessage "Discovered License information for $($LicenseInfo.ProductName)."
                    $inObj = [ordered] @{
                        'Product Name' = $LicenseInfo.ProductName
                        'Product Edition' = Switch ($LicenseInfo.EditionKey) {
                            "srm.enterprise.vm" {"Enterprise Edition"}
                            "srm.standard.vm" {"Standard Edition"}
                            default {$LicenseInfo.EditionKey}
                        }
                        'Product Version' = $LicenseInfo.ProductVersion
                        'Cost Unit' = Switch ($LicenseInfo.CostUnit) {
                            "vm" {"Per VM"}
                            default {$LicenseInfo.CostUnit}
                        }
                        'Total Licenses' = $LicenseInfo.Total
                        'Used Licenses' = $LicenseInfo.Used
                        'Expiration Date' = $LicenseInfo.ExpiryDate.ToShortDateString()
                        'Days to expiration' = $LicenseInfo.ExpiryDays
                    }
                    $OutObj += [pscustomobject]$inobj
                }
                $TableParams = @{
                    Name = "License Information - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
                    List = $true
                    ColumnWidths = 30, 70
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
        }#>
    }
    end {}
}