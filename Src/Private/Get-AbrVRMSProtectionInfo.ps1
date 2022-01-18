function Get-AbrVRMSProtectionInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware Replication Protection Status information.
    .DESCRIPTION

    .NOTES
        Version:        0.3.1
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
        Write-PScriboMessage "VMware Replication Protection Information InfoLevel set at $($InfoLevel.Summary)."
        Write-PscriboMessage "Collecting VMware Replication Protection Information."
    }

    process {
        try {
            $extensionmanager = get-view extensionmanager -Server $LocalvCenter
            $extension = $extensionmanager.extensionlist | where-object { $_.key -eq "com.vmware.vcHms" }
            if($extension.count -eq 1){
                $LocalVR = $extension.server.url.split("/")[2].split(":")[0]
            }
            if ($LocalVR) {
                Section -Style Heading2 'VMware Replication Protection Status' {
                    if ($Options.ShowDefinitionInfo) {
                        Paragraph "VMware vSphere Replication is a virtual machine data protection and disaster recovery solution. It is fully integrated with VMware vCenter Server and VMware vSphere Web Client, providing host-based, asynchronous replication of virtual machines."
                        BlankLine
                    }
                    Paragraph "The following section provides information on virtual machine replication status"
                    BlankLine
                    Section -Style Heading3 'Replicated Virtual Machine' {
                        Paragraph "The following table details virtual machine replicated by replication server $($LocalVR)."
                        BlankLine
                        $OutObj = @()
                        $ReplicatedVMs = Get-VM @Args -Server $LocalvCenter | Where-Object {($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -eq 'hbr_filter.destination' -and $_.Value } )}
                        if ($ReplicatedVMs) {
                            foreach ($ReplicatedVM in $ReplicatedVMs) {
                                if ($ReplicatedVM.VApp) {
                                    $ResourcesPool = $ReplicatedVM.VApp
                                    $Folder = $ReplicatedVM.VApp
                                }else {
                                    $ResourcesPool = $ReplicatedVM.ResourcePool
                                    $Folder = $ReplicatedVM.Folder
                                }
                                if ($ReplicatedVM.ResourcePool -like 'Resources') {
                                    $ResourcesPool = "Root Resource Pool"
                                }
                                Write-PscriboMessage "Discovered Recovery Site $($ReplicatedVM.Name)."
                                $inObj = [ordered] @{
                                    'VM Name' = $ReplicatedVM.Name
                                    'HW Version' = Switch (($ReplicatedVM.Version).count) {
                                        0 {"-"}
                                        default {($ReplicatedVM.Version).ToString().split("v")[1]}
                                    }
                                    'Folder' = $Folder
                                    'Resource Pool' = $ResourcesPool
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                        }

                        $TableParams = @{
                            Name = "VMware Replicated VMs - $($LocalVR.toUpper().split(".")[0])"
                            List = $false
                            ColumnWidths = 25, 15, 30, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'VM Name' | Table @TableParams
                    }
                    try {
                        Section -Style Heading3 'Non-Replicated Virtual Machine' {
                            Paragraph "The following table details virtual machine not replicated on vCenter Server $($LocalvCenter.Name)."
                            BlankLine
                            $OutObj = @()
                            $ReplicatedVMs = Get-VM @Args -Server $LocalvCenter | Where-Object {($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -ne 'hbr_filter.destination' -and $_.Value } )}
                            if ($ReplicatedVMs) {
                                foreach ($ReplicatedVM in $ReplicatedVMs) {
                                    if ($ReplicatedVM.VApp) {
                                        $ResourcesPool = $ReplicatedVM.VApp
                                        $Folder = $ReplicatedVM.VApp
                                    }else {
                                        $ResourcesPool = $ReplicatedVM.ResourcePool
                                        $Folder = $ReplicatedVM.Folder
                                    }
                                    if ($ReplicatedVM.ResourcePool -like 'Resources') {
                                        $ResourcesPool = "Root Resource Pool"
                                    }
                                    Write-PscriboMessage "Discovered Recovery Site $($ReplicatedVM.Name)."
                                    $inObj = [ordered] @{
                                        'VM Name' = $ReplicatedVM.Name
                                        'HW Version' = Switch (($ReplicatedVM.Version).count) {
                                            0 {"-"}
                                            default {($ReplicatedVM.Version).ToString().split("v")[1]}
                                        }
                                        'Folder' = $Folder
                                        'Resource Pool' = $ResourcesPool
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                            }

                            $TableParams = @{
                                Name = "VMware Replicated VMs - $($LocalVR.toUpper().split(".")[0])"
                                List = $false
                                ColumnWidths = 25, 15, 30, 30
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'VM Name' | Table @TableParams
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}