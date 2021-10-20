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
        Write-PScriboMessage "Protected Site InfoLevel set at $($InfoLevel.Protected)."
        Write-PscriboMessage "Collecting SRM Protected Site information."
    }

    process {
        try {
            $ProtectedSiteInfo = $SRMServer.ExtensionData.GetLocalSiteInfo()
            Section -Style Heading2 'Protected Site Summary' {
                Paragraph "In a typical Site Recovery Manager installation, the protected site provides business-critical datacenter services. The protected site can be any site where vCenter Server supports a critical business need."
                BlankLine
                Paragraph "The following section provides a summary of the Protected Site $($ProtectedSiteInfo.SiteName)."
                BlankLine
                $OutObj = @()
                if ($ProtectedSiteInfo) {
                    Write-PscriboMessage "Discovered Protected Site $($ProtectedSiteInfo.SiteName)."
                    $inObj = [ordered] @{
                        'Server Name' = $SRMServer.Name
                        'Protected Site Name' = $ProtectedSiteInfo.SiteName
                        'Protected Site ID' = $ProtectedSiteInfo.SiteUuid
                        'Solution User' = $SRMServer.ExtensionData.GetSolutionUserInfo().Username
                        'SRM Version' = $SRMServer.Version
                        'SRM Build' = $SRMServer.Build
                        'vCenter URL' = $ProtectedSiteInfo.VcUrl
                        'Lookup URL' = $ProtectedSiteInfo.LkpUrl
                        'Protection Group Count' = ($SRMServer.ExtensionData.Protection.ListProtectionGroups()).count
                        'Connected' = ConvertTo-TextYN $SRMServer.IsConnected
                    }
                    $OutObj += [pscustomobject]$inobj
                }

                if ($Healthcheck.Protected.Status) {
                    $ReplicaObj | Where-Object { $_.'Connected' -eq 'No'} | Set-Style -Style Warning -Property 'Connected'
                }

                $TableParams = @{
                    Name = "Protected Site Information - $($ProtectedSiteInfo.SiteName)"
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