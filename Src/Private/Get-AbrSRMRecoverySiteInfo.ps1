function Get-AbrSRMRecoverySiteInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Recovery Site information.
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
        Write-PScriboMessage "Recovery Site InfoLevel set at $($InfoLevel.Recovery)."
        Write-PscriboMessage "Collecting SRM Recovery Site information."
    }

    process {
        try {
            $RecoverySiteInfo = $LocalSRM.ExtensionData.GetPairedSite()
            Section -Style Heading2 'Recovery Site' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "In a typical Site Recovery Manager installation, the recovery site is an alternative infrastructure to which Site Recovery Manager can migrate services. The recovery site can be located thousands of miles away from the protected site. Conversely, the recovery site can be in the same room as a way of establishing redundancy. The recovery site is usually located in a facility that is unlikely to be affected by environmental, infrastructure, or other disturbances that affect the protected site."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the Recovery Site $($RecoverySiteInfo.Name)."
                BlankLine
                $OutObj = @()
                if ($RecoverySiteInfo) {
                    Write-PscriboMessage "Discovered Recovery Site $($RecoverySiteInfo.Name)."
                    $inObj = [ordered] @{
                        'Recovery Site Name' = $RecoverySiteInfo.Name
                        'Recovery Site ID' = $RecoverySiteInfo.Uuid
                        'Solution User' = $LocalSRM.ExtensionData.GetPairedSiteSolutionUserInfo().Username
                        'vCenter Host' = $RecoverySiteInfo.VcHost
                        'vCenter URL' = $RecoverySiteInfo.VcUrl
                        'Lookup URL' = $RecoverySiteInfo.LkpUrl
                        'Connected' = ConvertTo-TextYN $RecoverySiteInfo.Connected
                    }
                    $OutObj += [pscustomobject]$inobj
                }

                if ($Healthcheck.Recovery.Status) {
                    $ReplicaObj | Where-Object { $_.'Connected' -eq 'No'} | Set-Style -Style Warning -Property 'Connected'
                }

                $TableParams = @{
                    Name = "Recovery Site Information - $($RecoverySiteInfo.Name)"
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