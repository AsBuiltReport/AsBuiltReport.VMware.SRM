function Get-AbrSRMArrayPairs {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve VMware SRM Array Pairs information.
    .DESCRIPTION
        Documents the configuration of VMware SRM in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.2
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         @tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM
    #>
    begin {
        Write-PScriboMessage "Collecting Array Pairs information."
    }

    process {
        try {
            $LocalArrayPair = $LocalSRM.ExtensionData.Storage.QueryArrayManagers().GetArrayInfo()
            $RemoteArrayPair = $RemoteSRM.ExtensionData.Storage.QueryArrayManagers().GetArrayInfo()
            $LocalSRA = $LocalSRM.ExtensionData.Storage.QueryArrayManagers().getadapter().fetchinfo()
            $RemoteSRA = $RemoteSRM.ExtensionData.Storage.QueryArrayManagers().getadapter().fetchinfo()

            if (($LocalArrayPair) -and ($RemoteArrayPair)) {
                Section -Style Heading2 'Array Pairs' {
                    if ($Options.ShowDefinitionInfo) {
                    }
                    Paragraph "The following table provides information about the Storage Array Pairs which have been configured at each site."
                    BlankLine
                    $HashObj = @{}
                    $LocalObj = $LocalArrayPair.Key
                    $RemoteObj = $RemoteArrayPair.Key
                    $HashObj = @{
                        $LocalObj = $RemoteObj
                    }
                    $inObj = [ordered] @{
                        "$($ProtectedSiteName)" = "$($HashObj.Keys) <--> $($HashObj.Values)"
                        "$($RecoverySiteName)" = "$($HashObj.Values) <--> $($HashObj.Keys)"
                    }
                    $OutObj += [pscustomobject]$inobj


                    $TableParams = @{
                        Name = "Array Pairs"
                        List = $false
                        ColumnWidths = 50,50
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

    end {}

}