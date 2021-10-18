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
            $ProtectionGroups = $SRMServer.ExtensionData.Protection.ListProtectionGroups()
            Section -Style Heading2 'Protection Groups Summary' {
                Paragraph "In Site Recovery Manager, protection groups are a way of grouping VMs that will be recovered together. A protection group contains VMs whose data has been replicated by either array-based replication (ABR) or vSphere replication (VR). A protection group cannot contain VMs replicated by more than one replication solution and, a VM can only belong to a single protection group."
                BlankLine
                Paragraph "The following section provides a summary of the Protection Group configured under $($SRMServer.Name.split(".", 2).toUpper()[0])."
                BlankLine
                $OutObj = @()
                if ($ProtectionGroups) {
                    foreach ($ProtectionGroup in $ProtectionGroups) {
                        if ($ProtectionGroup.GetProtectionState() -ne "Shadowing") {
                            $ProtectionGroupInfo = $ProtectionGroup.GetInfo()
                            Write-PscriboMessage "Discovered Protection Group $($ProtectionGroupInfo.Name)."
                            $inObj = [ordered] @{
                                'Name' = $ProtectionGroupInfo.Name
                                'Description' = $ProtectionGroupInfo.Description
                                'Type' = $ProtectionGroupInfo.Type
                                'Protection State' = $ProtectionGroup.GetProtectionState()
                                'Protected Datastores' = ($ProtectedDatastores.Name | Sort-Object) -join ', '
                                'Protected VMs' = ($ProtectedVMs.Name | Sort-Object) -join ', '
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                    }
                }
                $TableParams = @{
                    Name = "Protection Group Information - $($ProtectedSiteInfo.SiteName)"
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
    }
    end {}
}