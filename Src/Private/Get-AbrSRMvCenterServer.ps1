function Get-AbrSRMvCenterServer {

    [CmdletBinding()]
    param (
    )

    begin {}

    process {
        try {
            Section -Style Heading2 'vCenter Server' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "VMware vCenter Server is advanced server management software that provides a centralized platform for controlling your VMware vSphere environments, allowing you to automate and deliver a virtual infrastructure across the hybrid cloud with confidence."
                    BlankLine
                }
                Paragraph "The following sections detail the configuration of vCenter Servers for sites $($ProtectedSiteName) and $($RecoverySiteName)."
                try {
                    Section -Style Heading3 "$($ProtectedSiteName)" {
                        Paragraph "The following table provides a configuration summary of the paired vCenter Server for the protected site."
                        BlankLine
                        $OutObj = @()
                        if ($LocalvCenter) {
                            $LocalSitevCenter = (Get-AdvancedSetting -Entity $LocalvCenter | Where-Object { $_.name -eq 'VirtualCenter.FQDN' }).Value
                            $LocalPSC = ((Get-AdvancedSetting -Entity $LocalvCenter | Where-Object { $_.name -eq 'config.vpxd.sso.admin.uri' }).Value).Split('/')[2]
                            Write-PScriboMessage "Gathering vCenter Server configuration for $($ProtectedSiteName)."
                            $LocalObj = [ordered] @{
                                'vCenter Server Name' = "$($LocalSitevCenter)"
                                'vCenter Server Version' = "$($LocalvCenter.Version)"
                                'vCenter Server Build' = "$($LocalvCenter.Build)"
                                'vCenter Server Host Name' = "$($LocalSitevCenter):443"
                                'Platform Services Controller' = "$($LocalPSC):443"

                            }
                            $OutObj += [pscustomobject]$LocalObj

                            $TableParams = @{
                                Name = "vCenter Server - $($ProtectedSiteName)"
                                List = $true
                                ColumnWidths = 40, 60
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }

                            $OutObj | Table @TableParams
                        }
                        try {
                            $Localvcenteradv = Get-AdvancedSetting -Entity $LocalvCenter
                            $LocalvcenterIP = ($Localvcenteradv | Where-Object { $_.name -like 'VirtualCenter.AutoManagedIPV4' }).Value
                            if ($LocalvcenterIP) {
                                $vCenterVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.IPAddress -match $LocalvcenterIP }
                                if ($vCenterVM) {
                                    Section -Style Heading4 "vCenter Server VM Configuration" {
                                        Paragraph "The following table details the hardware configuration of the paired vCenter Server for the protected site."
                                        BlankLine
                                        $OutObj = @()
                                        Write-PScriboMessage "Collecting vCenter Server configuration for $($vCenterVM.Name)."
                                        $inObj = [ordered] @{
                                            'VM Name' = $vCenterVM.Name
                                            'Number of CPUs' = $vCenterVM.NumCpu
                                            'Cores Per Socket' = $vCenterVM.CoresPerSocket
                                            'Memory' = "$($vCenterVM.MemoryGB) GB"
                                            'IP Address' = "$($vCenterVM.Guest.IPAddress)"
                                            'Host' = $vCenterVM.VMHost
                                            'OS Type' = Switch ($vCenterVM.GuestId) {
                                                "other3xLinux64Guest" { 'Photon OS' }
                                                default { $vCenterVM.GuestId }
                                            }
                                            'Provisioned Space' = "$([math]::Round(($vCenterVM.ProvisionedSpaceGB))) GB"
                                            'Used Space' = "$([math]::Round(($vCenterVM.UsedSpaceGB))) GB"
                                            'Datastores' = $vCenterVM.DatastoreIdList | ForEach-Object { Get-View $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name }
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "vCenter Server VM Configuration - $($vCenterVM.Name)"
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
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                        try {
                            $extensionmanager = Get-View extensionmanager -Server $LocalvCenter
                            $extension = $extensionmanager.extensionlist | Where-Object { $_.key -eq "com.vmware.vcHms" }
                            if ($extension.count -eq 1) {
                                $LocalVR = $extension.server.url.split("/")[2].split(":")[0]
                            }
                            $LocalVRFQDN = $LocalVR
                            $LocalVRHostName = $LocalVRFQDN.Split(".")[0]
                            if ($LocalVRFQDN) {
                                $LocalVRVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.HostName -match $LocalVRFQDN }
                            } elseif (!$LocalVRVM) {
                                $LocalVRVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.VmName -match $LocalVRHostName }
                            }
                            if ($LocalVRVM) {
                                try {
                                    Section -Style Heading4 "Replication Server VM Configuration" {
                                        Paragraph "The following table details the hardware configuration of the paired VMware Replication Server for the protected site."
                                        BlankLine
                                        $OutObj = @()
                                        Write-PScriboMessage "Collecting Replication Server configuration for $($LocalVRVM.Name)."
                                        $inObj = [ordered] @{
                                            'VM Name' = $LocalVRVM.Name
                                            'Number of CPUs' = $LocalVRVM.NumCpu
                                            'Cores Per Socket' = $LocalVRVM.CoresPerSocket
                                            'Memory' = "$($LocalVRVM.MemoryGB) GB"
                                            'Host' = $LocalVRVM.VMHost
                                            'OS Type' = Switch ($LocalVRVM.GuestId) {
                                                "other3xLinux64Guest" { 'Photon OS' }
                                                default { $LocalVRVM.GuestId }
                                            }
                                            'Provisioned Space' = "$([math]::Round(($LocalVRVM.ProvisionedSpaceGB))) GB"
                                            'Used Space' = "$([math]::Round(($LocalVRVM.UsedSpaceGB))) GB"
                                            'Datastores' = $LocalVRVM.DatastoreIdList | ForEach-Object { Get-View $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name }
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Replication Server VM Configuration - $($LocalVRVM.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }

                                        $OutObj | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
                try {
                    if ($RemotevCenter) {
                        $RecoverySiteInfo = $LocalSRM.ExtensionData.GetPairedSite()
                        Section -Style Heading3 "$($RecoverySiteName)" {
                            Paragraph "The following table provides a configuration summary of the paired vCenter Server for the recovery site."
                            BlankLine
                            $OutObj = @()
                            $RemoteSitevCenter = (Get-AdvancedSetting -Entity $RemotevCenter | Where-Object { $_.name -eq 'VirtualCenter.FQDN' }).Value
                            $RemotePSC = ((Get-AdvancedSetting -Entity $LocalvCenter | Where-Object { $_.name -eq 'config.vpxd.sso.admin.uri' }).Value).Split('/')[2]
                            Write-PScriboMessage "Collecting vCenter information for $($($RecoverySiteName))."

                            $RemoteObj = [ordered] @{
                                'vCenter Server Name' = "$($RemoteSitevCenter)"
                                'vCenter Server Version' = "$($RemotevCenter.Version)"
                                'vCenter Server Build' = "$($RemotevCenter.Build)"
                                'vCenter Server Host Name' = "$($RemoteSitevCenter):443"
                                'Platform Services Controller' = "$($RemotePSC):443"
                            }
                            $OutObj += [pscustomobject]$RemoteObj

                            $TableParams = @{
                                Name = "vCenter Server - $($RecoverySiteName)"
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
                                        $vCenterVM = (Get-VM -Server $RemotevCenter).Where{ $_.Guest.IPAddress -match $RemotevcenterIP }
                                        if ($vCenterVM) {
                                            Section -Style Heading4 "vCenter Server VM Configuration" {
                                                Paragraph "The following table details hardware configuration of the paired vCenter Server for the recovery site."
                                                BlankLine
                                                $OutObj = @()
                                                Write-PScriboMessage "Collecting vCenter Server configuration for $($vCenterVM.Name)."
                                                $inObj = [ordered] @{
                                                    'VM Name' = $vCenterVM.Name
                                                    'Number of CPUs' = $vCenterVM.NumCpu
                                                    'Cores Per Socket' = $vCenterVM.CoresPerSocket
                                                    'Memory' = "$($vCenterVM.MemoryGB) GB"
                                                    'IP Address' = "$($vCenterVM.Guest.IPAddress)"
                                                    'Host' = $vCenterVM.VMHost
                                                    'OS Type' = Switch ($vCenterVM.GuestId) {
                                                        "other3xLinux64Guest" { 'Photon OS' }
                                                        default { $vCenterVM.GuestId }
                                                    }
                                                    'Provisioned Space' = "$([math]::Round(($vCenterVM.ProvisionedSpaceGB))) GB"
                                                    'Used Space' = "$([math]::Round(($vCenterVM.UsedSpaceGB))) GB"
                                                    'Datastores' = $vCenterVM.DatastoreIdList | ForEach-Object { Get-View $_ | Select-Object -ExpandProperty Name }
                                                }
                                                $OutObj += [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "vCenter Server VM Configuration - $($vCenterVM.Name)"
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
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                            try {
                                $extensionmanager = Get-View extensionmanager -Server $RemotevCenter
                                $extension = $extensionmanager.extensionlist | Where-Object { $_.key -eq "com.vmware.vcHms" }
                                if ($extension.count -eq 1) {
                                    $RemoteVR = $extension.server.url.split("/")[2].split(":")[0]
                                }
                                $RemoteVRFQDM = $RemoteVR
                                $RemoteVRHostName = $RemoteVRFQDM.Split(".")[0]
                                if ($RemoteVRFQDM) {
                                    $RemoteVRVM = (Get-VM).Where{ $_.Guest.HostName -match $RemoteVRFQDM }
                                } elseif (!$RemoteVRVM) {
                                    $RemoteVRVM = (Get-VM).Where{ $_.Guest.VmName -match $RemoteVRHostName }
                                }
                                if ($RemoteVRVM) {
                                    Section -Style Heading4 "Replication Server VM Configuration" {
                                        Paragraph "The following table details the hardware configuration of the paired VMware Replication Server for the recovery site."
                                        BlankLine
                                        $OutObj = @()
                                        Write-PScriboMessage "Gathering Replication Server configuration for $($RemoteVRVM.Name)."
                                        $inObj = [ordered] @{
                                            'VM Name' = $RemoteVRVM.Name
                                            'Number of CPUs' = $RemoteVRVM.NumCpu
                                            'Cores Per Socket' = $RemoteVRVM.CoresPerSocket
                                            'Memory in GB' = $RemoteVRVM.MemoryGB
                                            'Host' = $RemoteVRVM.VMHost
                                            'OS Type' = Switch ($RemoteVRVM.GuestId) {
                                                "other3xLinux64Guest" { 'Photon OS' }
                                                default { $RemoteVRVM.GuestId }
                                            }
                                            'Provisioned Space GB' = "$([math]::Round(($RemoteVRVM.ProvisionedSpaceGB)))"
                                            'Used Space GB' = "$([math]::Round(($RemoteVRVM.UsedSpaceGB)))"
                                            'Datastores' = $RemoteVRVM.DatastoreIdList | ForEach-Object { Get-View $_ | Select-Object -ExpandProperty Name }
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Replication Server VM Configuration - $($RemoteVRVM.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    } else { Write-PScriboMessage -IsWarning "No Recovery Site vCenter connection has been detected. Deactivating Remote vCenter section" }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}
}