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
            Section -Style Heading2 'vCenter Summary' {
                Paragraph "VMware vCenter Server is advanced server management software that provides a centralized platform for controlling your VMware vSphere environments, allowing you to automate and deliver a virtual infrastructure across the hybrid cloud with confidence."
                BlankLine
                Paragraph "The following section provides a summary of the Connected vCenter on Sites $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)/$($SRMServer.ExtensionData.GetPairedSite().Name)."
                BlankLine
                try {
                    Section -Style Heading3 "$($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName) vCenter Information (Protected Site)" {
                        Paragraph "The following section provides a summary of the Connected vCenter on Site $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                        BlankLine
                        $OutObj = @()
                        if ($LocalvCenter -and $RemotevCenter) {
                            $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $LocalPSC = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
                            $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $RemotePSC = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
                            Write-PscriboMessage "Discovered vCenter information for $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)."
                            $LocalObj = [ordered] @{
                                'Server URL' = "https://$($LocalSitevCenter)/"
                                'Version' = "$($LocalvCenter.Version).$($LocalvCenter.Build)"
                                'Host Name' = "$($LocalSitevCenter):443"
                                'PSC Name' = "$($LocalPSC):443"

                            }
                            $OutObj += [pscustomobject]$LocalObj
                        }
                        $TableParams = @{
                            Name = "vCenter Information - $($SRMServer.ExtensionData.GetLocalSiteInfo().SiteName)"
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
                    $RecoverySiteInfo = $SRMServer.ExtensionData.GetPairedSite()
                    Section -Style Heading3 "$($RecoverySiteInfo.Name) vCenter Information (Recovery Site)" {
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
    }
    end {}
}