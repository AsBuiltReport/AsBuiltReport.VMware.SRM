function Get-AbrSRMSitePairs {

    begin {
        Write-PScriboMessage "Collecting Site Pairing information."
    }

    process {
        $LocalSiteInfo = $LocalSRM.ExtensionData.GetLocalSiteInfo()
        $RemoteSiteInfo = $LocalSRM.ExtensionData.GetPairedSite()

        if (($LocalSiteInfo) -or ($RemoteSiteInfo)) {
            Section -Style Heading2 "Site Pairs" {
                Paragraph "The following table summarize information about SRM Site Pairs."
                BlankLine
                $OutObj = @()
                if ($LocalSiteInfo) {
                    Write-PScriboMessage "Collecting site information for $($ProtectedSiteName)."
                    $inObj = [ordered] @{
                        'Site' = $LocalSiteInfo.SiteName
                        'SRM Server' = $LocalSRM.Name
                        'SRM Version' = $LocalSRM.Version
                        'SRM Build' = $LocalSRM.Build
                        'vCenter Server' = ($LocalSiteInfo.VcUrl).Split('/')[2].Split(':')[0]
                        'vCenter Version' = "$($LocalvCenter.Version)"
                        'vCenter Build' = "$($LocalvCenter.Build)"
                        'Protection Groups' = ($LocalSRM.ExtensionData.Protection.ListProtectionGroups()).count
                        'Recovery Plans' = ($LocalSRM.ExtensionData.Recovery.ListPlans()).count
                        'Connected' = ConvertTo-TextYN $LocalSRM.IsConnected
                    }
                    $OutObj += $inobj
                }

                if ($RemoteSiteInfo) {
                    Write-PScriboMessage "Collecting site information for $($RecoverySiteName)."
                    $inObj = [ordered] @{
                        'Site' = $RemoteSiteInfo.Name
                        'SRM Server' = $RemoteSRM.Name
                        'SRM Version' = $RemoteSRM.Version
                        'SRM Build' = $RemoteSRM.Build
                        'vCenter Server' = $RemoteSiteInfo.VcHost
                        'vCenter Version' = "$($RemotevCenter.Version)"
                        'vCenter Build' = "$($RemotevCenter.Build)"
                        'Protection Groups' = ($RemoteSRM.ExtensionData.Protection.ListProtectionGroups()).count
                        'Recovery Plans' = ($RemoteSRM.ExtensionData.Recovery.ListPlans()).count
                        'Connected' = ConvertTo-TextYN $RemoteSiteInfo.Connected
                    }
                    $OutObj += $inobj
                }

                $TableParams = @{
                    Name = "Site Pairs"
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