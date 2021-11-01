function Get-AbrSRMProtectionGroupInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Protection Group information.
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
        Write-PScriboMessage "Protection Group Site InfoLevel set at $($InfoLevel.ProtectionGroup)."
        Write-PscriboMessage "Collecting SRM Protection Group information."
    }

    process {
        try {
            Section -Style Heading2 'Protection Groups Summary' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "In Site Recovery Manager, protection groups are a way of grouping VMs that will be recovered together. A protection group contains VMs whose data has been replicated by either array-based replication (ABR) or vSphere replication (VR). A protection group cannot contain VMs replicated by more than one replication solution and, a VM can only belong to a single protection group."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the Protection Group configured under $($LocalSRM.Name.split(".", 2).toUpper()[0])."
                BlankLine
                $ProtectionGroups = $LocalSRM.ExtensionData.Protection.ListProtectionGroups()
                $OutObj = @()
                if ($ProtectionGroups) {
                    foreach ($ProtectionGroup in $ProtectionGroups) {
                        try {
                            if ($ProtectionGroup.ListRecoveryPlans()) {
                                $RecoveryPlan = $ProtectionGroup.ListRecoveryPlans().getinfo().Name
                            }

                            $ProtectionGroupInfo = $ProtectionGroup.GetInfo()
                            Write-PscriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                            $inObj = [ordered] @{
                                'Name' = $ProtectionGroupInfo.Name
                                'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                'Protection State' = $ProtectionGroup.GetProtectionState()
                                'Recovery Plan' = ConvertTo-EmptyToFiller $RecoveryPlan
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
                $TableParams = @{
                    Name = "Protection Group Information - $($ProtectionGroupInfo.Name)"
                    List = $False
                    ColumnWidths = 35, 15, 15, 35
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                try {
                    Section -Style Heading3 "Protection Groups" {
                        Paragraph "The following section provides detailed Protection Group informattion on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) ."
                        BlankLine
                        $ProtectionGroups = $LocalSRM.ExtensionData.Protection.ListProtectionGroups()
                        if ($ProtectionGroups) {
                            Section -Style Heading4 "VMRS Type Protection Groups" {
                                Paragraph "The following section provides detailed Protection Group informattion on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) ."
                                BlankLine
                                $OutObj = @()
                                foreach ($ProtectionGroup in $ProtectionGroups) {
                                    try {
                                        $ProtectionGroupInfo = $ProtectionGroup.GetInfo()
                                        $VMRSPG = $ProtectionGroupInfo | Where-Object {$_.Type -eq "VR"}
                                        if ($VMRSPG) {
                                            if ($ProtectionGroup.ListProtectedVMs()) {
                                                $ProtectedVMs = get-view $ProtectionGroup.ListProtectedVMs().vm.MoRef | Select-Object -ExpandProperty name
                                            }
                                            if ($ProtectionGroup.ListAssociatedVms()) {
                                                $AssociatedVMs = get-view $ProtectionGroup.ListAssociatedVms().MoRef | Select-Object -ExpandProperty name
                                            }

                                            if ($ProtectionGroupInfo.Type -eq "VR") {
                                                $inObj = [ordered] @{
                                                    'Name' = $ProtectionGroupInfo.Name
                                                    'Description' = ConvertTo-EmptyToFiller $ProtectionGroupInfo.Description
                                                    'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                                    'Associated VMs' =  (($AssociatedVMs | Sort-Object) -join ', ')
                                                    'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object) -join ', ')
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "VRMS Protection Group - $($ProtectionGroupInfo.Name)"
                                    List = $true
                                    ColumnWidths = 30, 70
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                        }
                        if ($ProtectionGroups) {
                            Section -Style Heading4 "SAN Type Protection Groups" {
                                Paragraph "The following section provides detailed Protection Group informattion on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) ."
                                BlankLine
                                $OutObj = @()
                                foreach ($ProtectionGroup in $ProtectionGroups) {
                                    try {
                                        $ProtectionGroupInfo = $ProtectionGroup.GetInfo()
                                        $VMRSPG = $ProtectionGroupInfo | Where-Object {$_.Type -eq "SAN"}
                                        if ($VMRSPG) {
                                            if ($ProtectionGroup.ListProtectedVMs()) {
                                                $ProtectedVMs = get-view $ProtectionGroup.ListProtectedVMs().vm.MoRef | Select-Object -ExpandProperty name
                                            }

                                            if ($ProtectionGroupInfo.Type -eq "SAN") {
                                                if ($ProtectionGroup.ListProtectedDatastores()) {
                                                    $ProtectedDatastores = get-view $ProtectionGroup.ListProtectedDatastores().MoRef | Select-Object -ExpandProperty name
                                                }
                                                $inObj = [ordered] @{
                                                    'Name' = $ProtectionGroupInfo.Name
                                                    'Description' = ConvertTo-EmptyToFiller $ProtectionGroupInfo.Description
                                                    'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                                    'Protected Datastores' = ConvertTo-EmptyToFiller (($ProtectedDatastores | Sort-Object) -join ', ')
                                                    'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object) -join ', ')
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "SAN Protection Group - $($ProtectionGroupInfo.Name)"
                                    List = $true
                                    ColumnWidths = 30, 70
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                        }
                        if ($InfoLevel.ProtectionGroup -ge 3) {
                            try {
                                $ProtectionGroups = $LocalSRM.ExtensionData.Protection.ListProtectionGroups()
                                foreach ($ProtectionGroup in $ProtectionGroups) {
                                    Section -Style Heading3 "$($ProtectionGroup.GetInfo().Name) Recovery PlaceHolder" {
                                        Paragraph "The following section provides detailed VM Recovery PlaceHolder informattion on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) ."
                                        BlankLine
                                        $OutObj = @()
                                        if ($ProtectionGroups) {
                                            if ($ProtectionGroup.ListProtectedVMs()) {
                                                $ProtectedVMs = $ProtectionGroup.ListProtectedVMs()
                                            }

                                            foreach ($ProtectedVM in $ProtectedVMs) {
                                                try {
                                                    $PlaceholderVmInfo = $ProtectionGroup.GetPlaceholderVmInfo($ProtectedVM)
                                                    $inObj = [ordered] @{
                                                        'VM Name' = get-vm -id $PlaceholderVmInfo.Vm
                                                        'Data Center' = get-view $PlaceholderVmInfo.Datacenter | Select-Object -ExpandProperty Name
                                                        'Compute Resource' = get-view $PlaceholderVmInfo.ComputeResource | Select-Object -ExpandProperty Name
                                                        'Host Name' = get-view $PlaceholderVmInfo.Host | Select-Object -ExpandProperty Name
                                                        'Resource Pool' = Switch (get-view $PlaceholderVmInfo.ResourcePool | Select-Object -ExpandProperty Name) {
                                                            "Resources" {"Root Resource Pool"}
                                                            default {get-view $PlaceholderVmInfo.ResourcePool | Select-Object -ExpandProperty Name}
                                                        }
                                                        'Folder Name' = get-folder -Id $PlaceholderVmInfo.Folder
                                                        'Is Repair Needed' = ConvertTo-TextYN $PlaceholderVmInfo.RepairNeeded
                                                        'Placeholder Creation Fault' = ConvertTo-EmptyToFiller $PlaceholderVmInfo.PlaceholderCreationFault
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                        }
                                        $TableParams = @{
                                            Name = "Protection Group Information - $($ProtectionGroupInfo.Name)"
                                            List = $true
                                            ColumnWidths = 30, 70
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
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}