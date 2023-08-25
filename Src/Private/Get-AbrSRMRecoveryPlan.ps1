function Get-AbrSRMRecoveryPlan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Recovery Plan information.
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
        $RecoveryPlans = $LocalSRM.ExtensionData.Recovery.ListPlans()
        if ($RecoveryPlans) {
            Section -Style Heading2 'Recovery Plans' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "A recovery plan is similar to an automated runbook that controls every step of the recovery process."
                    BlankLine
                }
                Paragraph "The following table provides a summary of the Recovery Plan configured under $($LocalSRM.Name.split(".", 2).toUpper()[0])."
                BlankLine

                $OutObj = @()
                foreach ($RecoveryPlan in $RecoveryPlans) {
                    try {
                        $RecoveryPlanInfo = $RecoveryPlan.GetInfo()
                        $RecoveryPlanPGs = foreach ($RecoveryPlanPG in $RecoveryPlan.getinfo().ProtectionGroups) {
                            $RecoveryPlanPG.GetInfo().Name
                        }

                        Write-PScriboMessage "Discovered Recovery Plan $($RecoveryPlanInfo.Name)."
                        $inObj = [ordered] @{
                            'Name' = $RecoveryPlanInfo.Name
                            'Description' = ConvertTo-EmptyToFiller $RecoveryPlanInfo.Description
                            'State' = $RecoveryPlanInfo.State
                            'Protection Groups' = ConvertTo-EmptyToFiller (($RecoveryPlanPGs | Sort-Object) -join ', ')
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) Virtual Machine Recovery Setting"
                    }
                }
                $TableParams = @{
                    Name = "Recovery Plan - $($RecoveryPlanInfo.Name)"
                    List = $False
                    ColumnWidths = 30, 25, 15, 30
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams

                if ($InfoLevel.RecoveryPlan -ge 2) {
                    try {
                        $RecoveryPlans = $LocalSRM.ExtensionData.Recovery.ListPlans()
                        if ($RecoveryPlans) {
                            Section -Style Heading3 'Virtual Machine Recovery Settings' {
                                Paragraph "The following section provides detailed per VM Recovery Settings informattion on $($ProtectedSiteName) ."
                                BlankLine
                                foreach ($RecoveryPlan in $RecoveryPlans) {
                                    try {
                                        Section -Style Heading3 "$($RecoveryPlan.getinfo().Name)" {
                                            $RecoveryPlanPGs = foreach ($RecoveryPlanPG in $RecoveryPlan.getinfo().ProtectionGroups) {
                                                $RecoveryPlanPG
                                            }
                                            $OutObj = @()
                                            foreach ($PG in $RecoveryPlanPGs) {
                                                try {
                                                    $VMs = $PG.ListProtectedVms()
                                                    foreach ($VM in $VMs) {
                                                        try {
                                                            $RecoverySettings = $PG.ListRecoveryPlans().GetRecoverySettings($VM.Vm.MoRef)
                                                            $DependentVMs = Switch ($RecoverySettings.DependentVmIds) {
                                                                "" { "--"; break }
                                                                $Null { "--"; break }
                                                                default { $RecoverySettings.DependentVmIds | ForEach-Object { Get-VM -Id $_ } }
                                                            }
                                                            $PrePowerOnCommand = @()
                                                            foreach ($PrePowerOnCommands in $RecoverySettings.PrePowerOnCallouts) {
                                                                try {
                                                                    if ($PrePowerOnCommands) {
                                                                        $PrePowerOnCommand += $PrePowerOnCommands | Select-Object @{Name = "Name"; E = { $_.Description } }, @{Name = 'Run In Vm'; E = { $_.RunInRecoveredVm } }, Timeout
                                                                    }
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                                }
                                                            }
                                                            $PosPowerOnCommand = @()
                                                            foreach ($PosPowerOnCommands in $RecoverySettings.PostPowerOnCallouts) {
                                                                try {
                                                                    if ($PosPowerOnCommands) {
                                                                        $PosPowerOnCommand += $PosPowerOnCommands | Select-Object @{Name = "Name"; E = { $_.Description } }, @{Name = 'Run In Vm'; E = { $_.RunInRecoveredVm } }, Timeout
                                                                    }
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
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
                                                                        "" { "--"; break }
                                                                        $Null { "--"; break }
                                                                        default { $PrePowerOnCommand | ForEach-Object { "Name: $($_.Name), Run In VM: $(ConvertTo-TextYN $_.'Run In Vm'), TimeOut: $($_.Timeout)/s" }; break }
                                                                    }
                                                                    'Post PowerOn Callouts' = Switch ($PosPowerOnCommand) {
                                                                        "" { "--"; break }
                                                                        $Null { "--"; break }
                                                                        default { $PosPowerOnCommand | ForEach-Object { "Name: $($_.Name), Run In VM: $(ConvertTo-TextYN $_.'Run In Vm'), TimeOut: $($_.Timeout)/s" }; break }
                                                                    }
                                                                    'Dependent VMs' = ($DependentVMs | Sort-Object -Unique) -join ", "
                                                                }
                                                                $OutObj = [pscustomobject]$inobj

                                                                $TableParams = @{
                                                                    Name = "VM Recovery Settings - $($VM.VmName)"
                                                                    List = $true
                                                                    ColumnWidths = 50, 50
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

                                            if ($InfoLevel.RecoveryPlan -eq 2 -and (-Not [string]::IsNullOrEmpty($OutObj))) {
                                                $TableParams = @{
                                                    Name = "VM Recovery Settings - $($VM.VmName)"
                                                    List = $False
                                                    ColumnWidths = 16, 10, 12, 12, 12, 12, 12, 14
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
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) Virtual Machine Recovery Setting"
                    }
                }
            }
        }
    }
    end {}
}
