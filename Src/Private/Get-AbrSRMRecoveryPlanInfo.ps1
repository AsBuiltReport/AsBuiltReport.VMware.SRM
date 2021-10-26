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
                try {
                    $RecoveryPlans = $LocalSRM.ExtensionData.Recovery.ListPlans()
                    if ($RecoveryPlans) {
                        foreach ($RecoveryPlan in $RecoveryPlans) {
                            Section -Style Heading3 "$($RecoveryPlan.getinfo().Name) Virtual Machine Recovery Setting" {
                                Paragraph "The following section provides a summary of the Recovery Plan configured under $($LocalSRM.Name.split(".", 2).toUpper()[0])."
                                BlankLine
                                $RecoveryPlanPGs = foreach ($RecoveryPlanPG in $RecoveryPlan.getinfo().ProtectionGroups) {
                                    $RecoveryPlanPG
                                }
                                $OutObj = @()
                                foreach ($PG in $RecoveryPlanPGs) {
                                    $VMs = $PG.ListProtectedVms()
                                    foreach ($VM in $VMs) {
                                        $RecoverySettings = $PG.ListRecoveryPlans().GetRecoverySettings($VM.Vm.MoRef)
                                        Write-PScriboMessage "Discovered VM Setting $($VM.VmName)."
                                        $inObj = [ordered] @{
                                            'Name' = $VM.VmName
                                            'Status' = $RecoverySettings.Status
                                            'Recovery Priority' = $RecoverySettings.RecoveryPriority
                                            'Skip Guest ShutDown' = ConvertTo-TextYN $RecoverySettings.SkipGuestShutDown
                                            'PowerOn Timeout' = "$($RecoverySettings.PowerOnTimeoutSeconds)/s"
                                            'PowerOn Delay' = "$($RecoverySettings.PowerOnDelaySeconds)/s"
                                            'PowerOff Timeout' = "$($RecoverySettings.PowerOffTimeoutSeconds)/s"
                                            'Final Power State' = $RecoverySettings.FinalPowerState
                                            'Pre PowerOn Callouts' = ConvertTo-EmptyToFiller $RecoverySettings.PrePowerOnCallouts
                                            'Post PowerOn Callouts' = ConvertTo-EmptyToFiller $RecoverySettings.PostPowerOnCallouts
                                            'Dependent VMs' = ConvertTo-EmptyToFiller $RecoverySettings.DependentVmIds
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                }

                                $TableParams = @{
                                    Name = "Virtual Machine Recovery Setting - $($RecoveryPlan.getinfo().Name)"
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
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) Virtual Machine Recovery Setting"
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}