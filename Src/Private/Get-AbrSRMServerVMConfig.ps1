function Get-AbrSRMServerVMConfig {


    begin {}

    process {
        if ($LocalvCenter) {
            $LocalSRMFQDN = $LocalSRM.Name
            $LocalSRMHostName = ($LocalSRM.Name).Split(".")[0]
            if ($LocalSRMFQDN) {
                $LocalSRMVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.HostName -match $LocalSRMFQDN }
            }
            if (-not $LocalSRMVM) {
                $LocalSRMVM = (Get-VM -Server $LocalvCenter).Where{ $_.Guest.VmName -match $LocalSRMHostName }
            }
            if ($LocalSRMVM) {
                Section -Style Heading4 "SRM Server VM Configuration" {
                    Paragraph "The following table details the hardware inventory of the SRM protected site, $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName)."
                    BlankLine
                    $OutObj = @()
                    Write-PScriboMessage "Collecting SRM Server VM configuration for $($LocalSRMVM.Name)."
                    $inObj = [ordered] @{
                        'VM Name' = $LocalSRMVM.Name
                        'Number of CPUs' = $LocalSRMVM.NumCpu
                        'Cores Per Socket' = $LocalSRMVM.CoresPerSocket
                        'Memory in GB' = $LocalSRMVM.MemoryGB
                        'Host' = $LocalSRMVM.VMHost
                        'OS Type' = Switch ($LocalSRMVM.GuestId) {
                            "other3xLinux64Guest" { 'Photon OS' }
                            default { $LocalSRMVM.GuestId }
                        }
                        'Provisioned Space GB' = "$([math]::Round(($LocalSRMVM.ProvisionedSpaceGB)))"
                        'Used Space GB' = "$([math]::Round(($LocalSRMVM.UsedSpaceGB)))"
                        'Datastores' = $LocalSRMVM.DatastoreIdList | ForEach-Object { Get-View $_ -Server $LocalvCenter | Select-Object -ExpandProperty Name }
                    }
                    $OutObj += [pscustomobject]$inobj

                    $TableParams = @{
                        Name = "SRM Server VM Configuration - $($LocalSRMVM.Name)"
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

        if ($RemotevCenter) {
            $extensionmanager = Get-View extensionmanager -Server $RemotevCenter
            $extension = $extensionmanager.extensionlist | Where-Object { $_.key -eq "com.vmware.vcDR" }
            if ($extension.count -eq 1) {
                $RemoteSRMServer = $extension.server.url.split("/")[2].split(":")[0]
            }
            $RemoteSRMFQDN = $RemoteSRMServer
            $RemoteSRMHostName = $RemoteSRMFQDN.Split(".")[0]
            if ($RemoteSRMFQDN) {
                $RemoteSRMVM = (Get-VM -Server $RemotevCenter).Where{ $_.Guest.HostName -match $RemoteSRMFQDN }
            }
            if (-not $RemoteSRMVM) {
                $RemoteSRMVM = (Get-VM -Server $RemotevCenter).Where{ $_.Guest.VmName -match $RemoteSRMHostName }
            }
            if ($RemoteSRMVM) {
                Section -Style Heading4 "SRM Server VM Configuration" {
                    Paragraph "The following table provides the hardware configuration of the SRM Server for the recovery site, $($RecoverySiteName)."
                    BlankLine
                    $OutObj = @()
                    Write-PScriboMessage "Collecting SRM Server VM configuration for $($RemoteSRMVM.Name)."
                    $inObj = [ordered] @{
                        'VM Name' = $RemoteSRMVM.Name
                        'Number of CPUs' = $RemoteSRMVM.NumCpu
                        'Cores Per Socket' = $RemoteSRMVM.CoresPerSocket
                        'Memory in GB' = $RemoteSRMVM.MemoryGB
                        'Host' = $RemoteSRMVM.VMHost
                        'OS Type' = Switch ($RemoteSRMVM.GuestId) {
                            "other3xLinux64Guest" { 'Photon OS' }
                            default { $RemoteSRMVM.GuestId }
                        }
                        'Provisioned Space GB' = "$([math]::Round(($RemoteSRMVM.ProvisionedSpaceGB)))"
                        'Used Space GB' = "$([math]::Round(($RemoteSRMVM.UsedSpaceGB)))"
                        'Datastores' = $RemoteSRMVM.DatastoreIdList | ForEach-Object { Get-View $_ | Select-Object -ExpandProperty Name }
                    }
                    $OutObj += [pscustomobject]$inobj

                    $TableParams = @{
                        Name = "SRM Server VM Configuration - $($RemoteSRMVM.Name)"
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

    end {}
}