function Get-AbrSRMSummaryInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Summary information.
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
            Section -Style Heading2 'vCenter Information' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "VMware vCenter Server is advanced server management software that provides a centralized platform for controlling your VMware vSphere environments, allowing you to automate and deliver a virtual infrastructure across the hybrid cloud with confidence."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the Connected vCenter on Sites $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)/$($LocalSRM.ExtensionData.GetPairedSite().Name)."
                BlankLine
                try {
                    Section -Style Heading3 "$($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) vCenter Information" {
                        Paragraph "The following section provides a summary of the paired vCenter on Site $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                        BlankLine
                        $OutObj = @()
                        if ($LocalvCenter) {
                            $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
                            $LocalPSC = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local"
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
                        try {
                            $Localvcenteradv = Get-AdvancedSetting -Entity $LocalvCenter
                            $LocalvcenterIP = ($Localvcenteradv | Where-Object { $_.name -like 'VirtualCenter.AutoManagedIPV4' }).Value
                            if ($LocalvcenterIP) {
                                $vCenterVM = Get-VM * -Server $LocalvCenter | where-object {$_.Guest.IPAddress -match $LocalvcenterIP}
                                if ($vCenterVM) {
                                    Section -Style Heading4 "vCenter Server VM Properties" {
                                        Paragraph "The following section provides the hardware properties of the Protected Site vCenter $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                                        BlankLine
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered SRM Permissions $($Permission.Name)."
                                        $inObj = [ordered] @{
                                            'VM Name' = $vCenterVM.Name
                                            'Number of CPUs' = $vCenterVM.NumCpu
                                            'Cores Per Socket' = $vCenterVM.CoresPerSocket
                                            'Memory in GB' = $vCenterVM.MemoryGB
                                            'Host' = $vCenterVM.VMHost
                                            'Guest Id' = $vCenterVM.GuestId
                                            'Provisioned Space GB' = "$([math]::Round(($vCenterVM.ProvisionedSpaceGB)))"
                                            'Used Space GB' = "$([math]::Round(($vCenterVM.UsedSpaceGB)))"
                                            'Datastores' = $vCenterVM.DatastoreIdList | ForEach-Object {get-view $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name}
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "vCenter VM Properties - $($vCenterVM.Name)"
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
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                        try {
                            $extensionmanager = get-view extensionmanager -Server $LocalvCenter
                            $extension = $extensionmanager.extensionlist | where-object { $_.key -eq "com.vmware.vcHms" }
                            if($extension.count -eq 1){
                                $LocalVR = $extension.server.url.split("/")[2].split(":")[0]
                            }
                            $LocalVRFQDM = $LocalVR
                            $LocalVRHostName = $LocalVRFQDM.Split(".")[0]
                            if ($LocalVRFQDM) {
                                $LocalVRVM = Get-VM * -Server $LocalvCenter | where-object {$_.Guest.HostName -match $LocalVRFQDM}
                            }
                            elseif (!$LocalVRVM) {
                                $LocalVRVM = Get-VM * -Server $LocalvCenter | where-object {$_.Guest.VmName -match $LocalVRHostName}
                            }
                            if ($LocalVRVM) {
                                Section -Style Heading4 "Replication Server VM Properties" {
                                    Paragraph "The following section provides the hardware properties of the VMware Replication server on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                                    BlankLine
                                    $OutObj = @()
                                    Write-PscriboMessage "Discovered VR VM Properties $($LocalVRVM.Name)."
                                    $inObj = [ordered] @{
                                        'VM Name' = $LocalVRVM.Name
                                        'Number of CPUs' = $LocalVRVM.NumCpu
                                        'Cores Per Socket' = $LocalVRVM.CoresPerSocket
                                        'Memory in GB' = $LocalVRVM.MemoryGB
                                        'Host' = $LocalVRVM.VMHost
                                        'Guest Id' = $LocalVRVM.GuestId
                                        'Provisioned Space GB' = "$([math]::Round(($LocalVRVM.ProvisionedSpaceGB)))"
                                        'Used Space GB' = "$([math]::Round(($LocalVRVM.UsedSpaceGB)))"
                                        'Datastores' = $LocalVRVM.DatastoreIdList | ForEach-Object {get-view $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name}
                                    }
                                    $OutObj += [pscustomobject]$inobj

                                    $TableParams = @{
                                        Name = "VMware Replication VM Properties - $($LocalVRVM.Name)"
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
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
                try {
                    if ($RemotevCenter) {
                        $RecoverySiteInfo = $LocalSRM.ExtensionData.GetPairedSite()
                        Section -Style Heading3 "$($RecoverySiteInfo.Name) vCenter Information" {
                            Paragraph "The following section provides a summary of the paired vCenter on Site $($RecoverySiteInfo.Name)."
                            BlankLine
                            $OutObj = @()
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

                            $TableParams = @{
                                Name = "vCenter Information - $($($RecoverySiteInfo.Name))"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            try {
                                if ($RemotevCenter) {
                                    $Remotevcenteradv = Get-AdvancedSetting -Entity $RemotevCenter
                                    $RemotevcenterIP = ($Remotevcenteradv | Where-Object { $_.name -like 'VirtualCenter.AutoManagedIPV4' }).Value
                                    if ($RemotevcenterIP) {
                                        $vCenterVM = Get-VM * -Server $RemotevCenter | where-object {$_.Guest.IPAddress -match $RemotevcenterIP}
                                        if ($vCenterVM) {
                                            Section -Style Heading4 "vCenter Server VM Properties" {
                                                Paragraph "The following section provides the hardware properties of the Recovery Site vCenter $($RecoverySiteInfo.Name)."
                                                BlankLine
                                                $OutObj = @()
                                                Write-PscriboMessage "Discovered SRM Permissions $($Permission.Name)."
                                                $inObj = [ordered] @{
                                                    'VM Name' = $vCenterVM.Name
                                                    'Number of CPUs' = $vCenterVM.NumCpu
                                                    'Cores Per Socket' = $vCenterVM.CoresPerSocket
                                                    'Memory in GB' = $vCenterVM.MemoryGB
                                                    'Host' = $vCenterVM.VMHost
                                                    'Guest Id' = $vCenterVM.GuestId
                                                    'Provisioned Space GB' = "$([math]::Round(($vCenterVM.ProvisionedSpaceGB)))"
                                                    'Used Space GB' = "$([math]::Round(($vCenterVM.UsedSpaceGB)))"
                                                    'Datastores' = $vCenterVM.DatastoreIdList | ForEach-Object {get-view $_ | Select-Object -ExpandProperty Name}
                                                }
                                                $OutObj += [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "vCenter VM Properties - $($vCenterVM.Name)"
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
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                            try {
                                $extensionmanager = get-view extensionmanager -Server $RemotevCenter
                                $extension = $extensionmanager.extensionlist | where-object { $_.key -eq "com.vmware.vcHms" }
                                if($extension.count -eq 1){
                                    $RemoteVR = $extension.server.url.split("/")[2].split(":")[0]
                                }
                                $RemoteVRFQDM = $RemoteVR
                                $RemoteVRHostName = $RemoteVRFQDM.Split(".")[0]
                                if ($RemoteVRFQDM) {
                                    $RemoteVRVM = Get-VM * | where-object {$_.Guest.HostName -match $RemoteVRFQDM}
                                }
                                elseif (!$RemoteVRVM) {
                                    $RemoteVRVM = Get-VM * | where-object {$_.Guest.VmName -match $RemoteVRHostName}
                                }
                                if ($RemoteVRVM) {
                                    Section -Style Heading4 "Replication Server VM Properties" {
                                        Paragraph "The following section provides the hardware properties of the VMware Replication server on $($RecoverySiteInfo.Name)."
                                        BlankLine
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered VR VM Properties $($RemoteVRVM.Name)."
                                        $inObj = [ordered] @{
                                            'VM Name' = $RemoteVRVM.Name
                                            'Number of CPUs' = $RemoteVRVM.NumCpu
                                            'Cores Per Socket' = $RemoteVRVM.CoresPerSocket
                                            'Memory in GB' = $RemoteVRVM.MemoryGB
                                            'Host' = $RemoteVRVM.VMHost
                                            'Guest Id' = $RemoteVRVM.GuestId
                                            'Provisioned Space GB' = "$([math]::Round(($RemoteVRVM.ProvisionedSpaceGB)))"
                                            'Used Space GB' = "$([math]::Round(($RemoteVRVM.UsedSpaceGB)))"
                                            'Datastores' = $RemoteVRVM.DatastoreIdList | ForEach-Object {get-view $_ | Select-Object -ExpandProperty Name}
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "VMware Replication VM Properties - $($RemoteVRVM.Name)"
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
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    }
                    else {Write-PscriboMessage -IsWarning "No Recovery Site vCenter connection has been detected. Deactivating Remote vCenter section"}
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