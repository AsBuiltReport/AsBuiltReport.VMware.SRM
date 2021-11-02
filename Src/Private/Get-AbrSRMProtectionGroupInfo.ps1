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

                                            if ($InfoLevel.ProtectionGroup -eq 1) {
                                                $inObj = [ordered] @{
                                                    'Name' = $ProtectionGroupInfo.Name
                                                    'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                                    'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            if ($InfoLevel.ProtectionGroup -ge 2) {
                                                $inObj = [ordered] @{
                                                    'Name' = $ProtectionGroupInfo.Name
                                                    'Description' = ConvertTo-EmptyToFiller $ProtectionGroupInfo.Description
                                                    'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                                    'Associated VMs' =  (($AssociatedVMs | Sort-Object -Unique) -join ', ')
                                                    'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($InfoLevel.ProtectionGroup -eq 1) {
                                    $TableParams = @{
                                        Name = "VRMS Protection Group - $($ProtectionGroupInfo.Name)"
                                        List = $false
                                        ColumnWidths = 35, 15, 15, 35
                                    }
                                }
                                if ($InfoLevel.ProtectionGroup -ge 2) {
                                    $TableParams = @{
                                        Name = "VRMS Protection Group - $($ProtectionGroupInfo.Name)"
                                        List = $true
                                        ColumnWidths = 30, 70
                                    }
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                        }
                        if ($ProtectionGroups) {
                            Section -Style Heading4 "SAN Type Protection Groups" {
                                $OutObj = @()
                                foreach ($ProtectionGroup in $ProtectionGroups) {
                                    try {
                                        $ProtectionGroupInfo = $ProtectionGroup.GetInfo()
                                        $VMRSPG = $ProtectionGroupInfo | Where-Object {$_.Type -eq "SAN"}
                                        if ($VMRSPG) {
                                            if ($ProtectionGroup.ListProtectedVMs()) {
                                                $ProtectedVMs = get-view $ProtectionGroup.ListProtectedVMs().vm.MoRef | Select-Object -ExpandProperty name
                                            }

                                            if ($InfoLevel.ProtectionGroup -eq 1) {
                                                if ($ProtectionGroup.ListProtectedDatastores()) {
                                                    $ProtectedDatastores = get-view $ProtectionGroup.ListProtectedDatastores().MoRef | Select-Object -ExpandProperty name
                                                }
                                                $inObj = [ordered] @{
                                                    'Name' = $ProtectionGroupInfo.Name
                                                    'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                                    'Protected Datastores' = ConvertTo-EmptyToFiller (($ProtectedDatastores | Sort-Object) -join ', ')
                                                    'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }

                                            if ($InfoLevel.ProtectionGroup -ge 2) {
                                                if ($ProtectionGroup.ListProtectedDatastores()) {
                                                    $ProtectedDatastores = get-view $ProtectionGroup.ListProtectedDatastores().MoRef | Select-Object -ExpandProperty name
                                                }
                                                $inObj = [ordered] @{
                                                    'Name' = $ProtectionGroupInfo.Name
                                                    'Description' = ConvertTo-EmptyToFiller $ProtectionGroupInfo.Description
                                                    'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                    'Protection State' = $ProtectionGroup.GetProtectionState()
                                                    'Protected Datastores' = ConvertTo-EmptyToFiller (($ProtectedDatastores | Sort-Object -Unique) -join ', ')
                                                    'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($InfoLevel.ProtectionGroup -eq 1) {
                                    $TableParams = @{
                                        Name = "SAN Protection Group - $($ProtectionGroupInfo.Name)"
                                        List = $False
                                        ColumnWidths = 26, 10, 11, 26, 27
                                    }
                                }
                                if ($InfoLevel.ProtectionGroup -ge 2) {
                                    $TableParams = @{
                                        Name = "SAN Protection Group - $($ProtectionGroupInfo.Name)"
                                        List = $true
                                        ColumnWidths = 30, 70
                                    }
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                        }
                        if ($InfoLevel.ProtectionGroup -ge 2) {
                            try {
                                Section -Style Heading3 'Virtual Machine Protection Properties Summary' {
                                    Paragraph "The following section provides detailed VM Recovery PlaceHolder informattion on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) ."
                                    BlankLine
                                    $ProtectionGroups = $LocalSRM.ExtensionData.Protection.ListProtectionGroups()
                                    foreach ($ProtectionGroup in $ProtectionGroups) {
                                        Section -Style Heading4 "$($ProtectionGroup.GetInfo().Name) Protection Properties (PlaceHolder)" {
                                            $OutObj = @()
                                            if ($ProtectionGroups) {
                                                if ($ProtectionGroup.ListProtectedVMs()) {
                                                    $ProtectedVMs = $ProtectionGroup.ListProtectedVMs()
                                                }

                                                foreach ($ProtectedVM in $ProtectedVMs) {
                                                    try {
                                                        $PlaceholderVmInfo = $ProtectionGroup.GetPlaceholderVmInfo($ProtectedVM)
                                                        if ($InfoLevel.ProtectionGroup -eq 2) {
                                                            $inObj = [ordered] @{
                                                                'VM Name' = get-vm -id $PlaceholderVmInfo.Vm | Sort-Object -Unique
                                                                'Resource Pool' = Switch (get-view $PlaceholderVmInfo.ResourcePool | Select-Object -ExpandProperty Name -Unique) {
                                                                    "Resources" {"Root Resource Pool"}
                                                                    default {get-view $PlaceholderVmInfo.ResourcePool | Select-Object -ExpandProperty Name -Unique}
                                                                }
                                                                'Folder Name' = get-folder -Id $PlaceholderVmInfo.Folder | Sort-Object -Unique
                                                                'Is Repair Needed' = ConvertTo-TextYN $PlaceholderVmInfo.RepairNeeded
                                                                'Placeholder Creation Fault' = ConvertTo-EmptyToFiller $PlaceholderVmInfo.PlaceholderCreationFault
                                                            }
                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                        if ($InfoLevel.ProtectionGroup -ge 3) {
                                                            $inObj = [ordered] @{
                                                                'VM Name' = get-vm -id $PlaceholderVmInfo.Vm | Sort-Object -Unique
                                                                'Data Center' = get-view $PlaceholderVmInfo.Datacenter | Select-Object -ExpandProperty Name -Unique
                                                                'Compute Resource' = get-view $PlaceholderVmInfo.ComputeResource | Select-Object -ExpandProperty Name -Unique
                                                                'Host Name' = get-view $PlaceholderVmInfo.Host | Select-Object -ExpandProperty Name -Unique
                                                                'Resource Pool' = Switch (get-view $PlaceholderVmInfo.ResourcePool | Select-Object -ExpandProperty Name -Unique) {
                                                                    "Resources" {"Root Resource Pool"}
                                                                    default {get-view $PlaceholderVmInfo.ResourcePool | Select-Object -ExpandProperty Name -Unique}
                                                                }
                                                                'Folder Name' = get-folder -Id $PlaceholderVmInfo.Folder | Sort-Object -Unique
                                                                'Is Repair Needed' = ConvertTo-TextYN $PlaceholderVmInfo.RepairNeeded
                                                                'Placeholder Creation Fault' = ConvertTo-EmptyToFiller $PlaceholderVmInfo.PlaceholderCreationFault
                                                            }
                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }
                                            }
                                            if ($InfoLevel.ProtectionGroup -eq 2) {
                                                $TableParams = @{
                                                    Name = "VM Recovery PlaceHolder - $($ProtectionGroup.GetInfo().Name)"
                                                    List = $False
                                                    ColumnWidths = 20, 25, 25, 10, 20
                                                }
                                            }
                                            if ($InfoLevel.ProtectionGroup -ge 3) {
                                                $TableParams = @{
                                                    Name = "VM Recovery PlaceHolder - $($ProtectionGroup.GetInfo().Name)"
                                                    List = $true
                                                    ColumnWidths = 30, 70
                                                }
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