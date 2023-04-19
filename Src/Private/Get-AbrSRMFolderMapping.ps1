function Get-AbrSRMFolderMapping {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Folder Mapping information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PScriboMessage "Collecting Folder Mapping information."
    }

    process {
        $FolderMappings = $LocalSRM.ExtensionData.InventoryMapping.GetFolderMappings()
        if ($FolderMappings) {
            Section -Style Heading2 'Folder Mappings' {
                if ($Options.ShowDefinitionInfo) {
                    Paragraph "Folder mappings allow you to specify how Site Recovery Manager maps virtual machine folders on the protected site to virtual machine folders on the recovery site."
                    Blankline
                }
                $OutObj = @()
                foreach ($ObjMap in $FolderMappings) {
                    try {
                        $HashObj = $Null
                        $LocalObj = Get-View $ObjMap.PrimaryObject -Server $LocalvCenter | Select-Object -ExpandProperty Name -Unique
                        $RemoteObj = Get-View $ObjMap.SecondaryObject -Server $RemotevCenter | Select-Object -ExpandProperty Name -Unique
                        $HashObj = @{
                            $LocalObj = $RemoteObj
                        }
                        $inObj = [ordered] @{
                            "$($ProtectedSiteName)" = $HashObj.Keys
                            "$($RecoverySiteName)" = $HashObj.Values
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Folder Mappings"
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