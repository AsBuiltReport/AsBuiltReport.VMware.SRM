function Get-AbrSRMLicense {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM licesning information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.3
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
        Write-PScriboMessage "Collecting licensing information."
    }

    process {
        $LocalLicenseInfo = $LocalSRM.ExtensionData.GetLicenseInfo()
        $RemoteLicenseInfo = $RemoteSRM.ExtensionData.GetLicenseInfo()
        if (($LocalLicenseInfo) -or ($RemoteLicenseInfo)) {
            Section -Style Heading2 'Licensing' {
                Paragraph "The following table provides information about configured licensing at each site."
                BlankLine
                $OutObj = @()
                if ($LocalLicenseInfo) {
                    Write-PScriboMessage "Discovered License information for $($LocalLicenseInfo.ProductName) at $($ProtectedSiteName)."
                    $inObj = [ordered] @{
                        'Site' = $($ProtectedSiteName)
                        'Product Name' = $LocalLicenseInfo.ProductName
                        'Product Edition' = Switch ($LocalLicenseInfo.EditionKey) {
                            "srm.eval.vm" { "Product Evaluation" }
                            "srm.enterprise.vm" { "Enterprise Edition" }
                            "srm.standard.vm" { "Standard Edition" }
                            default { $LocalLicenseInfo.EditionKey }
                        }
                        'Product Version' = $LocalLicenseInfo.ProductVersion
                        'Cost Unit' = Switch ($LocalLicenseInfo.CostUnit) {
                            "vm" { "Per VM" }
                            default { $LocalLicenseInfo.CostUnit }
                        }
                        'Total Licenses' = $LocalLicenseInfo.Total
                        'Used Licenses' = $LocalLicenseInfo.Used
                        'Expiration Date' = $LocalLicenseInfo.ExpiryDate.ToShortDateString()
                        'Days to Expiration' = $LocalLicenseInfo.ExpiryDays
                    }
                    $OutObj += $inobj
                }

                if ($RemoteLicenseInfo) {
                    Write-PScriboMessage "Discovered License information for $($RemoteLicenseInfo.ProductName) at $($RecoverySiteName)."
                    $inObj = [ordered] @{
                        'Site' = $($RecoverySiteName)
                        'Product Name' = $RemoteLicenseInfo.ProductName
                        'Product Edition' = Switch ($RemoteLicenseInfo.EditionKey) {
                            "srm.eval.vm" { "Product Evaluation" }
                            "srm.enterprise.vm" { "Enterprise Edition" }
                            "srm.standard.vm" { "Standard Edition" }
                            default { $RemoteLicenseInfo.EditionKey }
                        }
                        'Product Version' = $RemoteLicenseInfo.ProductVersion
                        'Cost Unit' = Switch ($RemoteLicenseInfo.CostUnit) {
                            "vm" { "Per VM" }
                            default { $RemoteLicenseInfo.CostUnit }
                        }
                        'Total Licenses' = $RemoteLicenseInfo.Total
                        'Used Licenses' = $RemoteLicenseInfo.Used
                        'Expiration Date' = $RemoteLicenseInfo.ExpiryDate.ToShortDateString()
                        'Days to expiration' = $RemoteLicenseInfo.ExpiryDays
                    }
                    $OutObj += $inobj
                }

                if ($Healthcheck.Licensing) {
                    $OutObj | Where-Object { $_.'Product Edition' -like 'Evaluation' } | Set-Style -Style Warning
                }

                $TableParams = @{
                    Name = "Licensing"
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