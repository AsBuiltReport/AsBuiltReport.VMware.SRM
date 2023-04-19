function Get-AbrSRMRecoverySite {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Recovery Site information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         @rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>

    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Collecting SRM Recovery Site information."
    }

    process {
        $RecoverySiteInfo = $LocalSRM.ExtensionData.GetPairedSite()
        if ($RecoverySiteInfo) {
            Write-PScriboMessage "Collecting SRM recovery site information for $($RecoverySiteName)."
            Section -Style Heading3 'Recovery Site' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "In a typical Site Recovery Manager installation, the recovery site is an alternative infrastructure to which Site Recovery Manager can migrate services. The recovery site can be located thousands of miles away from the protected site. Conversely, the recovery site can be in the same room as a way of establishing redundancy. The recovery site is usually located in a facility that is unlikely to be affected by environmental, infrastructure, or other disturbances that affect the protected site."
                    BlankLine
                }
                Paragraph "The following table provides information for the recovery site $($RecoverySiteName)."
                BlankLine

                $OutObj = @()
                $inObj = [ordered] @{
                    'Recovery Site Name' = $RecoverySiteInfo.Name
                    'Recovery Site ID' = $RecoverySiteInfo.Uuid
                    'SRM Server Name' = $RemoteSRM.Name
                    'SRM Server Version' = $RemoteSRM.Version
                    'SRM Server Build' = $RemoteSRM.Build
                    'vCenter Server Name' = $RecoverySiteInfo.VcHost
                    'Number of Protection Groups' = ($RemoteSRM.ExtensionData.Protection.ListProtectionGroups()).count
                    'Connected' = ConvertTo-TextYN $RecoverySiteInfo.Connected
                }
                $OutObj += [pscustomobject]$inobj

                if ($Healthcheck.Recovery.Status) {
                    $ReplicaObj | Where-Object { $_.'Connected' -eq 'No' } | Set-Style -Style Warning -Property 'Connected'
                }

                $TableParams = @{
                    Name = "Recovery Site - $($RecoverySiteName)"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }
    end {}
}