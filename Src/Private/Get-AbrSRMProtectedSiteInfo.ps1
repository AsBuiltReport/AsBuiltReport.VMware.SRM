function Get-AbrSRMProtectedSiteInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Protected Site information.
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
        Write-PscriboMessage "Collecting SRM Protected Site information."
    }

    process {
        try {
            $LocalSiteInfo = $SRMServer.ExtensionData.GetLocalSiteInfo()
            Section -Style Heading2 'Protected Site Summary' {
                Paragraph "In a typical Site Recovery Manager installation, the protected site provides business-critical datacenter services. The protected site can be any site where vCenter Server supports a critical business need. "
                BlankLine
                Paragraph "The following section provides a summary of the Protected Site $($LocalSiteInfo.SiteName)."
                BlankLine
                $OutObj = @()
                if ($LocalSiteInfo) {
                    Write-PscriboMessage "Discovered Protected Site $($LocalSiteInfo.SiteName)."
                    $inObj = [ordered] @{
                        'Server Name' = $SRMServer.Name
                        'Site Name' = $LocalSiteInfo.SiteName
                        'Site ID' = $LocalSiteInfo.SiteUuid
                        'Solution User' = $SRMServer.ExtensionData.GetSolutionUserInfo().Username
                        'SRM Version' = $SRMServer.Version
                        'SRM Build' = $SRMServer.Build
                        'vCenter URL' = $LocalSiteInfo.VcUrl
                        'Lookup URL' = $LocalSiteInfo.LkpUrl
                        'Protection Group Count' = ($SRMServer.ExtensionData.Protection.ListProtectionGroups()).count
                    }
                    $OutObj += [pscustomobject]$inobj
                }
                $TableParams = @{
                    Name = "Protected Site Information - $($LocalSiteInfo.SiteName)"
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