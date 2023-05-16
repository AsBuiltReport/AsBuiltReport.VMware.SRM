function Get-AbrSRMPermission {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM permissions information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.2
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
        Write-PScriboMessage "Collecting permissions information."
    }

    process {
        $LocalVIPermissions = Get-VIPermission -Server $LocalvCenter | Where-Object { $_.Role -like "SRM*" } | Select-Object @{Name = "Name"; E = { (Get-VIRole -Name  $_.Role | Select-Object -ExpandProperty ExtensionData).Info.Label } }, Principal, Propagate, IsGroup, Entity, Role
        $RemoteVIPermissions = Get-VIPermission -Server $RemotevCenter | Where-Object { $_.Role -like "SRM*" } | Select-Object @{Name = "Name"; E = { (Get-VIRole -Name  $_.Role | Select-Object -ExpandProperty ExtensionData).Info.Label } }, Principal, Propagate, IsGroup, Entity, Role
        if (($LocalVIPermissions) -or ($RemoteVIPermissions)) {
            Section -Style Heading2 'Permissions' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "Site Recovery Manager includes a set of roles. Each role includes a set of privileges, which allow users with those roles to complete different actions. Roles can have overlapping sets of privileges and actions."
                    Blankline
                }
                Paragraph "The following table provides information about the permissions which have been configured at each site."
                BlankLine

                if ($LocalVIPermissions) {
                    Section -Style NOTOCHeading3 -ExcludeFromTOC $($ProtectedSiteName) {
                        $OutObj = @()
                        foreach ($LocalVIPermission in $LocalVIPermissions) {
                            Write-PScriboMessage "Discovered SRM Permissions $($LocalVIPermission.Name)."
                            $inObj = [ordered] @{
                                'User/Group' = $LocalVIPermission.Principal
                                'Is Group?' = ConvertTo-TextYN $LocalVIPermission.IsGroup
                                'Role' = $LocalVIPermission.Name | Sort-Object -Unique
                                'Defined In' = $LocalVIPermission.Entity
                                'Propagate' = ConvertTo-TextYN $LocalVIPermission.Propagate
                            }
                            $OutObj += [pscustomobject]$inobj
                        }

                        $TableParams = @{
                            Name = "Permissions - $($ProtectedSiteName)"
                            List = $false
                            ColumnWidths = 42, 12, 20, 14, 12
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }

                        $OutObj | Sort-Object -Property 'Role' | Table @TableParams
                    }
                }

                if ($RemoteVIPermissions) {
                    Section -Style NOTOCHeading3 -ExcludeFromTOC $($RecoverySiteName) {
                        $OutObj = @()
                        foreach ($RemoteVIPermission in $RemoteVIPermissions) {
                            Write-PScriboMessage "Discovered SRM Permissions $($RemoteVIPermission.Name)."
                            $inObj = [ordered] @{
                                'User/Group' = $RemoteVIPermission.Principal
                                'Is Group?' = ConvertTo-TextYN $RemoteVIPermission.IsGroup
                                'Role' = $RemoteVIPermission.Name | Sort-Object -Unique
                                'Defined In' = $RemoteVIPermission.Entity
                                'Propagate' = ConvertTo-TextYN $RemoteVIPermission.Propagate
                            }
                            $OutObj += [pscustomobject]$inobj
                        }

                        $TableParams = @{
                            Name = "Permissions - $($RecoverySiteName)"
                            List = $false
                            ColumnWidths = 42, 12, 20, 14, 12
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }

                        $OutObj | Sort-Object -Property 'Role' | Table @TableParams
                    }
                }
            }
        }
    }

    end {}
}