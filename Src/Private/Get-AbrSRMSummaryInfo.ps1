function Get-AbrSRMSummaryInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Summary information.
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
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
            $LicenseInfo = $LocalSRM.ExtensionData.GetLicenseInfo()
            Section -Style Heading2 'vCenter Information' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "VMware vCenter Server is advanced server management software that provides a centralized platform for controlling your VMware vSphere environments, allowing you to automate and deliver a virtual infrastructure across the hybrid cloud with confidence."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the Connected vCenter on Sites $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)/$($LocalSRM.ExtensionData.GetPairedSite().Name)."
                BlankLine
                try {
                    Section -Style Heading3 "$($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) vCenter Information" {
                        Paragraph "The following section provides a summary of the Connected vCenter on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        BlankLine
                        $OutObj = @()
                        if ($LocalvCenter -and $RemotevCenter) {
                            $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $LocalPSC = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
                            $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $RemotePSC = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
                            Write-PscriboMessage "Discovered vCenter information for $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                            $LocalObj = [ordered] @{
                                'Server URL' = "https://$($LocalSitevCenter)/"
                                'Version' = "$($LocalvCenter.Version).$($LocalvCenter.Build)"
                                'Host Name' = "$($LocalSitevCenter):443"
                                'PSC Name' = "$($LocalPSC):443"

                            }
                            $OutObj += [pscustomobject]$LocalObj
                        }
                        $TableParams = @{
                            Name = "vCenter Information - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
                            List = $true
                            ColumnWidths = 40, 60
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
                    $RecoverySiteInfo = $LocalSRM.ExtensionData.GetPairedSite()
                    Section -Style Heading3 "$($RecoverySiteInfo.Name) vCenter Information" {
                        Paragraph "The following section provides a summary of the Connected vCenter on Site $($RecoverySiteInfo.Name)."
                        BlankLine
                        $OutObj = @()
                        if ($LocalvCenter -and $RemotevCenter) {
                            $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $LocalPSC = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
                            $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $RemotePSC = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
                            Write-PscriboMessage "Discovered vCenter information for $($($RecoverySiteInfo.Name))."

                            $RemoteObj = [ordered] @{
                                'Server URL' = "https://$($RemoteSitevCenter)/"
                                'Version' = "$($RemotevCenter.Version).$($RemotevCenter.Build)"
                                'Host Name' = "$($RemoteSitevCenter):443"
                                'PSC Name' = "$($RemotePSC):443"

                            }
                            $OutObj += [pscustomobject]$RemoteObj
                        }
                        $TableParams = @{
                            Name = "vCenter Information - $($($RecoverySiteInfo.Name))"
                            List = $true
                            ColumnWidths = 40, 60
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
        try {
            $LicenseInfo = $LocalSRM.ExtensionData.GetLicenseInfo()
            Section -Style Heading2 'Licenses Information' {
                Paragraph "The following section provides a summary of the License Feature on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
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
                    Name = "License Information - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
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
            $Permissions = Get-VIPermission -Server $LocalvCenter | Where-Object {$_.Role -like "SRM*"} | Select-Object @{Name = "Name"; E = {(get-virole -Name  $_.Role | Select-Object -ExpandProperty ExtensionData).Info.Label}},Principal,Propagate,IsGroup
            Section -Style Heading2 'SRM Permissions' {
                Paragraph "The following section provides a summary of the SRM Permissions on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                BlankLine
                $OutObj = @()
                if ($Permissions) {
                    foreach ($Permission in $Permissions) {
                        Write-PscriboMessage "Discovered SRM Permissions $($Permission.Name)."
                        $inObj = [ordered] @{
                            'Role' = $Permission.Name | Sort-Object -Unique
                            'Principal' = $Permission.Principal
                            'Propagate' = ConvertTo-TextYN $Permission.Propagate
                            'Is Group' = ConvertTo-TextYN $Permission.IsGroup

                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                $TableParams = @{
                    Name = "SRM Permissions - $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)"
                    List = $false
                    ColumnWidths = 38, 38, 12, 12
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