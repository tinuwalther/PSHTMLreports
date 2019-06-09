<#
    https://getbootstrap.com/
#>

function Get-MWADataSet{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String[]] $Destination
    )

    $tcptest = Test-PsNetTping -Destination $Destination -CommonTcpPort HTTPS -MaxTimeout 200 -MinTimeout 10
    $array = foreach($tping in $tcptest){
        $nslookup = Test-PsNetDig -Destination $tping.Destination
        [PSCustomObject]@{
            
            TcpSucceeded         = $tping.TcpSucceeded
            TcpPort              = $tping.TcpPort
            TcpTimeStamp         = $tping.TimeStamp
            TcpDestination       = $tping.Destination
            TcpStatusDescription = $tping.StatusDescription
            TcpMinTimeout        = $tping.MinTimeout
            TcpMaxTimeout        = $tping.MaxTimeout
            TcpTimeMs            = $tping.TimeMs

            DigSucceeded         = $nslookup.Succeeded
            DigInputString       = $nslookup.InputString
            DigDestination       = $nslookup.Destination
            DigIpV4Address       = $nslookup.IpV4Address
            DigIpV6Address       = $nslookup.IpV6Address
            DigTimeMs            = $nslookup.TimeMs

        }
    }
    return $array
}

function Format-MWADataSet{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [Object] $Object
    )

    $array = foreach ($item in $Object) {
        [pscustomobject]@{
            Name   = $item.Tcpdestination
            TimeMS = $item.TcpTimeMS
        }
    }
    return $array
}

if(-not(Get-Module -Name PSHTML)){
    Import-Module PSHTML
}

if(-not(Get-Module -Name PsNetTools)){
    Import-Module PsNetTools
}

$PieCanvasID      = "piecanvas"
$DoughnutCanvasID = "Doughnutcanvas"
$BarCanvasID      = "barcanvas"

$HTML = html {

    head{

        title "PSHTML-PsNetTools"
        Write-PSHTMLAsset -Name Jquery
        Write-PSHTMLAsset -Name BootStrap
        Write-PSHTMLAsset -Name Chartjs

        div -Class "container" {
            p -Class "border" {
                h1 "Combined PSHTML and PsNetTools report"
            }
        }
    } 

    body{

        $test = Get-MWADataSet -Destination 'xing.de','bing.com','swiss.cj','sbb.ch','gkb.ch'
        $test | ForEach-Object {
            $total += $_.TcpTimeMs
        }

        div -Class "container" {

            p {
                "List some result from PsNetTools queries"
            }

            p {
                h2 "Summary"
            }

            div -class "container" {
                div -Class "row align-items-center" {
                    div -Class "col-sm" {
                        canvas -Height 300px -Width 300px -Id $PieCanvasID {}
                    }
                    div -Class "col-sm" {
                        canvas -Height 300px -Width 300px -Id $BarCanvasID {}
                    }
                    div -Class "col-sm" {
                        canvas -Height 300px -Width 300px -Id $DoughnutCanvasID {}
                    }
                }
            }

            script -content {

                $data   = $test | Group-Object TcpDestination
                $counts = $data | ForEach-Object {$_.Count}
                $labels = $data.Name
                $colors = @("yellow","red","green","orange","blue")
                
                $dsp1   = New-PSHTMLChartPieDataSet -Data $counts -BackgroundColor $colors
                New-PSHTMLChart -type pie -DataSet $dsp1 -title "Count of Tcp Tests" -Labels $labels -CanvasID $PieCanvasID 

                $data   = Format-MWADataSet -Object $test #| Group-Object TimeMs
                $counts = $data.TimeMs
                $labels = $data.Name

                $dsb1 = New-PSHTMLChartBarDataSet -Data $counts -label "TimeMs" -backgroundColor 'blue' -hoverBackgroundColor 'red' -borderColor 'red' -hoverBorderColor 'red'
                New-PSHTMLChart -type bar -DataSet $dsb1 -title "TimeMs of Tcp Results" -Labels $labels -CanvasID $BarCanvasID 

                $data   = $test | Group-Object TcpStatusDescription
                $counts = $data | ForEach-Object {$_.Count}
                $labels = $data.Name
                $colors = @("green","yellow", "red")

                $dsd1 = New-PSHTMLChartDoughnutDataSet -Data $counts -backgroundcolor $colors -hoverbackgroundColor $Colors
                New-PSHTMLChart -Type doughnut -DataSet $dsd1 -title "Amount of Tcp Results" -Labels $labels -CanvasID $DoughnutCanvasID 

            }
        
            p {
                h2 "Details"
            }

            div {

                Table -Class "table table-responsive table-sm table-hover" -content {

                    Thead -Class "thead-dark" {

                        Th {"TimeStamp"}
                        Th {"TcpSucceeded"}
                        Th {"TcpPort"}
                        Th {"Target"}
                        Th {"IpV4Address"}
                        Th {"IpV6Address"}
                        Th {"StatusDescription"}
                        Th {"MinTimeout"}
                        Th {"MaxTimeout"}
                        Th {"TimeMs"}

                    }

                    Tbody {

                        $test | Sort-Object TcpTimeMS -Descending | ForEach-Object {

                            tr {
                                td {$_.TcpTimeStamp}
                                td {$_.TcpSucceeded}
                                td {$_.TcpPort}
                                td {$_.TcpDestination}
                                td {
                                    if($_.DigIpV4Address){
                                        foreach($item in $_.DigIpV4Address){
                                            $output += "$($item), "
                                        }
                                        if($output.EndsWith(', ')){$output.TrimEnd(', ')}
                                    }
                                }
                                td {
                                    if($_.DigIpV6Address){
                                        $_.DigIpV6Address
                                    }
                                }
                                td {$_.TcpStatusDescription}
                                td {$_.TcpMinTimeout}
                                td {$_.TcpMaxTimeout}
                                td {$_.TcpTimeMs}
                            }

                        }

                    }

                    #ConvertTo-PSHTMLtable -Object $process
                }

                p -Class "font-weight-bold" {
                    "The query for these $($test.count) targets took a total of {0} milliseconds." -f ($total)
                }

            }

        }

    }

    Footer {

        div -Class "container" {
            p {
                a "Visite me on github.io" -href "https://tinuwalther.github.io/" -Target "_blank" 
                a " | Bootstrap help" -href "https://getbootstrap.com/" -Target "_blank" 
            }
        }

    }
}

$Root = Split-Path -parent $PSCommandPath
$Path = "$($Root)\example.html"
$Html | Out-File -FilePath $Path -Encoding utf8
Start-Process $Path 