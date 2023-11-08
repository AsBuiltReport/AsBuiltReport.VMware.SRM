function Get-AbrSRMProtectionGroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Protection Group information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.3
        Author:         Jonathan Colon & Tim Carman
        Twitter:        @jcolonfzenpr / @tpcarman
        Github:         @rebelinux / @tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>

    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Collecting SRM Protection Group information."
    }

    process {
        $ProtectionGroups = $LocalSRM.ExtensionData.Protection.ListProtectionGroups()
        if ($ProtectionGroups) {
            #region Collect Protection Group information
            Section -Style Heading2 'Protection Groups' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "A protection group is a collection of virtual machines that are protected together."
                    BlankLine
                }
                Paragraph "The following table provides a summary of the protection groups configured in $($LocalSRM.Name.split(".", 2).toUpper()[0])."
                BlankLine

                $OutObj = @()
                foreach ($ProtectionGroup in $ProtectionGroups) {
                    try {
                        if ($ProtectionGroup.ListRecoveryPlans()) {
                            $RecoveryPlan = $ProtectionGroup.ListRecoveryPlans().getinfo().Name
                        }

                        $ProtectionGroupInfo = $ProtectionGroup.GetInfo()
                        Write-PScriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                        $inObj = [ordered] @{
                            'Name' = $ProtectionGroupInfo.Name
                            'Type' = $ProtectionGroupInfo.Type.ToUpper()
                            'Protection State' = $ProtectionGroup.GetProtectionState()
                            'Recovery Plan' = ConvertTo-EmptyToFiller $RecoveryPlan
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Protection Group - $($ProtectionGroupInfo.Name)"
                    List = $False
                    ColumnWidths = 35, 15, 15, 35
                }

                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                $OutObj | Table @TableParams
                try {
                    if ($ProtectionGroups) {
                        Section -Style Heading3 "Protection Group Configuration" {
                            Paragraph "The following section provides detailed information on the protection groups configured for $($ProtectedSiteName) ."
                            BlankLine
                            if ($ProtectionGroups.GetInfo() | Where-Object { $_.Type -like "VR" }) {
                                Section -Style Heading4 "VMRS Protection Groups" {
                                    if ($InfoLevel.ProtectionGroup -eq 1) {
                                        $OutObj = @()
                                        foreach ($ProtectionGroup in $ProtectionGroups) {
                                            try {
                                                $ProtectionGroupInfo = $ProtectionGroup.GetInfo() | Where-Object { $_.Type -like "VR" }
                                                if ($ProtectionGroupInfo) {
                                                    Write-PScriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                                                    if ($ProtectionGroup.ListProtectedVMs()) {
                                                        $ProtectedVMs = ConvertTo-VIobject $ProtectionGroup.ListProtectedVMs().vm.MoRef
                                                    }
                                                    else {
                                                        $ProtectedVMs = ""
                                                    }

                                                    $inObj = [ordered] @{
                                                        'Name' = $ProtectionGroupInfo.Name
                                                        'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                        'Protection State' = $ProtectionGroup.GetProtectionState()
                                                        'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                        $TableParams = @{
                                            Name = "VRMS Protection Group - $($ProtectionGroupInfo.Name)"
                                            List = $false
                                            ColumnWidths = 35, 15, 15, 35
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                    if ($InfoLevel.ProtectionGroup -ge 2) {
                                        foreach ($ProtectionGroup in $ProtectionGroups) {
                                            $OutObj = @()
                                            try {
                                                $ProtectionGroupInfo = $ProtectionGroup.GetInfo() | Where-Object { $_.Type -like "VR" }
                                                if ($ProtectionGroupInfo) {
                                                    Write-PScriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                                                    if ($ProtectionGroup.ListProtectedVMs()) {
                                                        $ProtectedVMs = ConvertTo-VIobject $ProtectionGroup.ListProtectedVMs().vm.MoRef
                                                    }
                                                    else {
                                                        $ProtectedVMs = ""
                                                    }
                                                    if ($ProtectionGroup.ListAssociatedVms()) {
                                                        $AssociatedVMs = ConvertTo-VIobject $ProtectionGroup.ListAssociatedVms().MoRef
                                                    }
                                                    else {
                                                        $AssociatedVMs = ""
                                                    }

                                                    $inObj = [ordered] @{
                                                        'Name' = $ProtectionGroupInfo.Name
                                                        'Description' = ConvertTo-EmptyToFiller $ProtectionGroupInfo.Description
                                                        'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                        'Protection State' = $ProtectionGroup.GetProtectionState()
                                                        'Associated VMs' = (($AssociatedVMs | Sort-Object -Unique) -join ', ')
                                                        'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

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
                                            } catch {
                                                Write-PScriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                    }
                                }
                            }
                            try {
                                if ($ProtectionGroups.GetInfo() | Where-Object { $_.Type -like "SAN" }) {
                                    Section -Style Heading4 "SAN Protection Groups" {
                                        $OutObj = @()
                                        if ($InfoLevel.ProtectionGroup -eq 1) {
                                            foreach ($ProtectionGroup in $ProtectionGroups) {
                                                try {
                                                    $ProtectionGroupInfo = $ProtectionGroup.GetInfo() | Where-Object { $_.Type -like "SAN" }
                                                    if ($ProtectionGroupInfo) {
                                                        Write-PScriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                                                        if ($ProtectionGroup.ListProtectedVMs()) {
                                                            $ProtectedVMs = ConvertTo-VIobject $ProtectionGroup.ListProtectedVMs().vm.MoRef
                                                        }
                                                        else {
                                                            $ProtectedVMs = ""
                                                        }

                                                        if ($ProtectionGroup.ListProtectedDatastores()) {
                                                            $ProtectedDatastores = ConvertTo-VIobject $ProtectionGroup.ListProtectedDatastores().MoRef
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
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "SAN Protection Groups Section: $($_.Exception.Message)"
                                                }
                                            }
                                            $TableParams = @{
                                                Name = "SAN Protection Group - $($ProtectionGroupInfo.Name)"
                                                List = $False
                                                ColumnWidths = 26, 10, 11, 26, 27
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                        if ($InfoLevel.ProtectionGroup -ge 2) {
                                            foreach ($ProtectionGroup in $ProtectionGroups) {
                                                try {
                                                    $ProtectionGroupInfo = $ProtectionGroup.GetInfo() | Where-Object { $_.Type -like "SAN" }
                                                    if ($ProtectionGroupInfo) {
                                                        Write-PScriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                                                        if ($ProtectionGroup.ListProtectedVMs()) {
                                                            $ProtectedVMs = ConvertTo-VIobject $ProtectionGroup.ListProtectedVMs().vm.MoRef
                                                        }
                                                        else {
                                                            $ProtectedVMs = ""
                                                        }

                                                        if ($ProtectionGroup.ListProtectedDatastores()) {
                                                            $ProtectedDatastores = ConvertTo-VIobject $ProtectionGroup.ListProtectedDatastores().MoRef
                                                        }
                                                        $inObj = [ordered] @{
                                                            'Name' = $ProtectionGroupInfo.Name
                                                            'Description' = ConvertTo-EmptyToFiller $ProtectionGroupInfo.Description
                                                            'Type' = $ProtectionGroupInfo.Type.ToUpper()
                                                            'Protection State' = $ProtectionGroup.GetProtectionState()
                                                            'Protected Datastores' = ConvertTo-EmptyToFiller (($ProtectedDatastores | Sort-Object -Unique) -join ', ')
                                                            'Protected VMs' = ConvertTo-EmptyToFiller (($ProtectedVMs | Sort-Object -Unique) -join ', ')
                                                        }
                                                        $OutObj = [pscustomobject]$inobj

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
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    }
                    if ($InfoLevel.ProtectionGroup -ge 2) {
                        try {
                            if ($RemotevCenter) {
                                Section -Style Heading3 'Virtual Machine Protection Properties' {
                                    Paragraph "The following section provides detailed VM Recovery PlaceHolder informattion for $($ProtectedSiteName) ."
                                    BlankLine
                                    $ProtectionGroups = $LocalSRM.ExtensionData.Protection.ListProtectionGroups()
                                    foreach ($ProtectionGroup in $ProtectionGroups) {
                                        try {
                                            Section -Style Heading4 "$($ProtectionGroup.GetInfo().Name)" {
                                                $OutObj = @()
                                                if ($ProtectionGroups) {
                                                    if ($ProtectionGroup.ListProtectedVMs()) {
                                                        $ProtectedVMs = $ProtectionGroup.ListProtectedVMs()
                                                    }
                                                    else {
                                                        $ProtectedVMs = ""
                                                    }
                                                    if ($InfoLevel.ProtectionGroup -eq 2) {
                                                        foreach ($ProtectedVM in $ProtectedVMs) {
                                                            try {
                                                                $PlaceholderVmInfo = $ProtectionGroup.GetPlaceholderVmInfo($ProtectedVM)
                                                                $inObj = [ordered] @{
                                                                    'VM Name' = Switch ($PlaceholderVmInfo.Vm) {
                                                                        "" { '--' }
                                                                        $null { '--' }
                                                                        default { Get-VM -Id $PlaceholderVmInfo.Vm | Sort-Object -Unique }
                                                                    }
                                                                    'Resource Pool' = Switch ($PlaceholderVmInfo.ResourcePool) {
                                                                        "Resources" { "Root Resource Pool" }
                                                                        default { ConvertTo-VIobject $PlaceholderVmInfo.ResourcePool }
                                                                    }
                                                                    'Folder Name' = Switch ($PlaceholderVmInfo.Folder) {
                                                                        "" { '--' }
                                                                        $null { '--' }
                                                                        default { (Get-Folder -Id $PlaceholderVmInfo.Folder | Sort-Object -Unique).Name }
                                                                    }
                                                                    'Is Repair Needed' = ConvertTo-TextYN $PlaceholderVmInfo.RepairNeeded
                                                                    'Placeholder Creation Fault' = ConvertTo-EmptyToFiller $PlaceholderVmInfo.PlaceholderCreationFault
                                                                }
                                                                $OutObj += [pscustomobject]$inobj
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning $_.Exception.Message
                                                            }
                                                        }
                                                        $TableParams = @{
                                                            Name = "VM Recovery PlaceHolder - $($ProtectionGroup.GetInfo().Name)"
                                                            List = $False
                                                            ColumnWidths = 20, 25, 25, 10, 20
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                    if ($InfoLevel.ProtectionGroup -eq 3) {
                                                        foreach ($ProtectedVM in $ProtectedVMs) {
                                                            try {
                                                                $PlaceholderVmInfo = $ProtectionGroup.GetPlaceholderVmInfo($ProtectedVM)
                                                                $inObj = [ordered] @{
                                                                    'VM Name' = Switch ($PlaceholderVmInfo.Vm) {
                                                                        "" { '--' }
                                                                        $null { '--' }
                                                                        default { Get-VM -Id $PlaceholderVmInfo.Vm | Sort-Object -Unique }
                                                                    }
                                                                    'Data Center' = ConvertTo-VIobject $PlaceholderVmInfo.Datacenter

                                                                    'Compute Resource' = ConvertTo-VIobject $PlaceholderVmInfo.ComputeResource
                                                                    'Host Name' = ConvertTo-VIobject $PlaceholderVmInfo.Host
                                                                    'Resource Pool' = Switch ($PlaceholderVmInfo.ResourcePool) {
                                                                        "Resources" { "Root Resource Pool" }
                                                                        default { ConvertTo-VIobject $PlaceholderVmInfo.ResourcePool }
                                                                    }
                                                                    'Folder Name' = Switch ($PlaceholderVmInfo.Folder) {
                                                                        "" { '--' }
                                                                        $null { '--' }
                                                                        default { Get-Folder -Id $PlaceholderVmInfo.Folder | Sort-Object -Unique }
                                                                    }
                                                                    'Is Repair Needed' = ConvertTo-TextYN $PlaceholderVmInfo.RepairNeeded
                                                                    'Placeholder Creation Fault' = ConvertTo-EmptyToFiller $PlaceholderVmInfo.PlaceholderCreationFault
                                                                }
                                                                $OutObj = [pscustomobject]$inobj

                                                                $TableParams = @{
                                                                    Name = "VM Recovery PlaceHolder - $($ProtectionGroup.GetInfo().Name)"
                                                                    List = $true
                                                                    ColumnWidths = 30, 70
                                                                }

                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                $OutObj | Table @TableParams
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning $_.Exception.Message
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }
            #endregion Collect Protection Group information
        }
    }
    end {}
}
