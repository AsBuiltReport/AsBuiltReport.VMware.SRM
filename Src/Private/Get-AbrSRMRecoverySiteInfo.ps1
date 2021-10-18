function Get-AbrSRMRecoverySiteInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Recovery Site information.
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
        Write-PscriboMessage "Collecting SRM Recovery Site information."
    }

    process {
        try {
            $RecoverySiteInfo = $SRMServer.ExtensionData.GetPairedSite()
            Section -Style Heading2 'Recovery Site Summary' {
                Paragraph "In a typical Site Recovery Manager installation, the recovery site is an alternative infrastructure to which Site Recovery Manager can migrate services. The recovery site can be located thousands of miles away from the protected site. Conversely, the recovery site can be in the same room as a way of establishing redundancy. The recovery site is usually located in a facility that is unlikely to be affected by environmental, infrastructure, or other disturbances that affect the protected site."
                BlankLine
                Paragraph "The following section provides a summary of the Recovery Site $($RecoverySiteInfo.Name)."
                BlankLine
                $OutObj = @()
                if ($RecoverySiteInfo) {
                    Write-PscriboMessage "Discovered Protected Site $($RecoverySiteInfo.Name)."
                    $inObj = [ordered] @{
                        'Paired Site Name' = $RecoverySiteInfo.Name
                        'Paired Site ID' = $RecoverySiteInfo.Uuid
                        'Paired Site Solution User' = $SRMServer.ExtensionData.GetPairedSiteSolutionUserInfo().Username
                        'Paired Site vCenter Host' = $RecoverySiteInfo.VcHost
                        'Paired Site vCenter URL' = $RecoverySiteInfo.VcUrl
                        'Paired Site Lookup URL' = $RecoverySiteInfo.LkpUrl
                        'Paired Site Connected' = $RecoverySiteInfo.Connected
                    }
                    $OutObj += [pscustomobject]$inobj
                }
                $TableParams = @{
                    Name = "Protected Site Information - $($RecoverySiteInfo.Name)"
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