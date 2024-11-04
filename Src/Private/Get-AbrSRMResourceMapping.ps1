function Get-AbrSRMResourceMapping {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Resource Mapping information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.6
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
        Write-PScriboMessage "Collecting Resource Mapping information."
    }

    process {
        $ResourceMappings = $LocalSRM.ExtensionData.InventoryMapping.GetResourcePoolMappings()
        if ($ResourceMappings) {
            Section -Style Heading2 'Resource Mappings' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "Reource mappings allow you to specify how Site Recovery Manager maps resources on the protected site to resources on the recovery site."
                    BlankLine
                }
                $OutObj = @()
                $HashObj = $Null
                foreach ($ObjMap in $ResourceMappings) {
                    try {
                        $LocalObj = Get-View $ObjMap.PrimaryObject -Server $LocalvCenter | Select-Object -ExpandProperty Name -Unique
                        $RemoteObj = Get-View $ObjMap.SecondaryObject -Server $RemotevCenter | Select-Object -ExpandProperty Name -Unique
                        $HashObj = @{
                            $LocalObj = $RemoteObj
                        }
                        $inObj = [ordered] @{
                            "$($ProtectedSiteName)" = Switch ($HashObj.Keys) {
                                "Resources" { "Root Resource Pool" }
                                default { $HashObj.Keys }
                            }
                            "$($RecoverySiteName)" = Switch ($HashObj.Values) {
                                "Resources" { "Root Resource Pool" }
                                default { $HashObj.Values }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Resource Mappings"
                    List = $false
                    ColumnWidths = 50, 50
                }

                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                $OutObj | Table @TableParams
            }
        }
    }

    end {}
}