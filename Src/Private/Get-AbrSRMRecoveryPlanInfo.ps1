function Get-AbrSRMRecoveryPlanInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve VMware SRM Recovery Plan information.
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
        Write-PScriboMessage "Recovery Plan InfoLevel set at $($InfoLevel.RecoveryPlan)."
        Write-PscriboMessage "Collecting SRM Protection Group information."
    }

    process {
        try {
            Section -Style Heading2 'Recovery Plans Summary' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "Recovery Plans in Site Recovery Manager are like an automated run book, controlling all the steps in the recovery process. The recovery plan is the level at which actions like failover, planned migration, testing and re-protect are conducted. A recovery plan contains one or more protection groups and a protection group can be included in more than one recovery plan. This provides for the flexibility to test or recover an application by itself and also test or recover a group of applications or the entire site."
                    BlankLine
                }
                Paragraph "The following section provides a summary of the Recovery Plan configured under $($LocalSRM.Name.split(".", 2).toUpper()[0])."
                BlankLine
                $RecoveryPlans = $LocalSRM.ExtensionData.Recovery.ListPlans()
                $OutObj = @()
                if ($RecoveryPlans) {
                    foreach ($RecoveryPlan in $RecoveryPlans) {
                        $RecoveryPlanInfo = $RecoveryPlan.GetInfo()
                        $RecoveryPlanPGs = foreach ($RecoveryPlanPG in $RecoveryPlan.getinfo().ProtectionGroups) {
                            $RecoveryPlanPG.GetInfo().Name
                        }

                        Write-PScriboMessage "Discovered Protection Group $($RecoveryPlanInfo.Name)."
                        $inObj = [ordered] @{
                            'Name' = $RecoveryPlanInfo.Name
                            'Description' = ConvertTo-EmptyToFiller $RecoveryPlanInfo.Description
                            'State' = $RecoveryPlanInfo.State
                            'Protection Groups' = ConvertTo-EmptyToFiller (($RecoveryPlanPGs | Sort-Object) -join ', ')
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    $TableParams = @{
                        Name = "Recovery Plan Config - $($RecoveryPlanInfo.Name)"
                        List = $False
                        ColumnWidths = 30, 25, 15, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
                if ($InfoLevel.RecoveryPlan -ge 2) {
                    try {
                        $RecoveryPlans = $LocalSRM.ExtensionData.Recovery.ListPlans()
                        if ($RecoveryPlans) {
                            Section -Style Heading3 'Virtual Machine Recovery Settings Summary' {
                                Paragraph "The following section provides detailed per VM Recovery Settings informattion on $($LocalSRM.ExtensionData.GetLocalSiteInfo().SiteName) ."
                                BlankLine
                                foreach ($RecoveryPlan in $RecoveryPlans) {
                                    Section -Style Heading3 "$($RecoveryPlan.getinfo().Name) VM Recovery Settings" {
                                        $RecoveryPlanPGs = foreach ($RecoveryPlanPG in $RecoveryPlan.getinfo().ProtectionGroups) {
                                            $RecoveryPlanPG
                                        }
                                        $OutObj = @()
                                        foreach ($PG in $RecoveryPlanPGs) {
                                            $VMs = $PG.ListProtectedVms()
                                            foreach ($VM in $VMs) {
                                                $RecoverySettings = $PG.ListRecoveryPlans().GetRecoverySettings($VM.Vm.MoRef)
                                                $DependentVMs = Switch ($RecoverySettings.DependentVmIds) {
                                                    "" {"-"; break}
                                                    $Null {"-"; break}
                                                    default {$RecoverySettings.DependentVmIds | ForEach-Object {get-vm -Id $_}}
                                                }
                                                $PrePowerOnCommand = @()
                                                foreach ($PrePowerOnCommands in $RecoverySettings.PrePowerOnCallouts) {
                                                    if ($PrePowerOnCommands) {
                                                        $PrePowerOnCommand += $PrePowerOnCommands | Select-Object @{Name="Name"; E={$_.Description}},@{Name='Run In Vm'; E={$_.RunInRecoveredVm}},Timeout
                                                    }
                                                }
                                                $PosPowerOnCommand = @()
                                                foreach ($PosPowerOnCommands in $RecoverySettings.PostPowerOnCallouts) {
                                                    if ($PosPowerOnCommands) {
                                                        $PosPowerOnCommand += $PosPowerOnCommands | Select-Object @{Name="Name"; E={$_.Description}},@{Name='Run In Vm'; E={$_.RunInRecoveredVm}},Timeout
                                                    }
                                                }
                                                Write-PScriboMessage "Discovered VM Setting $($VM.VmName)."
                                                if ($InfoLevel.RecoveryPlan -eq 2) {
                                                    $inObj = [ordered] @{
                                                        'Name' = $VM.VmName
                                                        'Status' = $RecoverySettings.Status.ToUpper()
                                                        'Recovery Priority' = $TextInfo.ToTitleCase($RecoverySettings.RecoveryPriority)
                                                        'Skip Guest ShutDown' = ConvertTo-TextYN $RecoverySettings.SkipGuestShutDown
                                                        'PowerOn Timeout' = "$($RecoverySettings.PowerOnTimeoutSeconds)/s"
                                                        'PowerOn Delay' = "$($RecoverySettings.PowerOnDelaySeconds)/s"
                                                        'PowerOff Timeout' = "$($RecoverySettings.PowerOffTimeoutSeconds)/s"
                                                        'Final Power State' = $TextInfo.ToTitleCase($RecoverySettings.FinalPowerState)
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                if ($InfoLevel.RecoveryPlan -eq 3) {
                                                    $inObj = [ordered] @{
                                                        'Name' = $VM.VmName
                                                        'Status' = $RecoverySettings.Status.ToUpper()
                                                        'Recovery Priority' = $TextInfo.ToTitleCase($RecoverySettings.RecoveryPriority)
                                                        'Skip Guest ShutDown' = ConvertTo-TextYN $RecoverySettings.SkipGuestShutDown
                                                        'PowerOn Timeout' = "$($RecoverySettings.PowerOnTimeoutSeconds)/s"
                                                        'PowerOn Delay' = "$($RecoverySettings.PowerOnDelaySeconds)/s"
                                                        'PowerOff Timeout' = "$($RecoverySettings.PowerOffTimeoutSeconds)/s"
                                                        'Final Power State' = $TextInfo.ToTitleCase($RecoverySettings.FinalPowerState)
                                                        'Pre PowerOn Callouts' = Switch ($PrePowerOnCommand) {
                                                            "" {"-"; break}
                                                            $Null {"-"; break}
                                                            default {$PrePowerOnCommand | ForEach-Object {"Name: $($_.Name), Run In VM: $(ConvertTo-TextYN $_.'Run In Vm'), TimeOut: $($_.Timeout)/s"}; break}
                                                        }
                                                        'Post PowerOn Callouts' = Switch ($PosPowerOnCommand) {
                                                            "" {"-"; break}
                                                            $Null {"-"; break}
                                                            default {$PosPowerOnCommand | ForEach-Object {"Name: $($_.Name), Run In VM: $(ConvertTo-TextYN $_.'Run In Vm'), TimeOut: $($_.Timeout)/s"}; break}
                                                        }
                                                        'Dependent VMs' = ($DependentVMs | Sort-Object -Unique) -join ", "
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                            }
                                        }

                                        if ($InfoLevel.RecoveryPlan -eq 2) {
                                            $TableParams = @{
                                                Name = "Virtual Machine Recovery Settings - $($RecoveryPlan.getinfo().Name)"
                                                List = $False
                                                ColumnWidths = 16, 10, 12, 12, 12, 12, 12, 14
                                            }
                                        }
                                        if ($InfoLevel.RecoveryPlan -eq 3) {
                                            $TableParams = @{
                                                Name = "Virtual Machine Recovery Settings - $($RecoveryPlan.getinfo().Name)"
                                                List = $true
                                                ColumnWidths = 50, 50
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
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) Virtual Machine Recovery Setting"
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "$($_.Exception.Message) Recovery Plans Summary"
        }
    }
    end {}
}