<#
    https://getbootstrap.com/
#>

function Get-MWADataSet{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String[]] $Destination
    )

    $tcptest = Test-PsNetTping -Destination $Destination -CommonTcpPort HTTPS -MaxTimeout 1000 -MinTimeout 10
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
            Name      = $item.Tcpdestination
            TcpTimeMS = $item.TcpTimeMS
            DigTimeMS = $item.DigTimeMS
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

        $test = Get-MWADataSet -Destination 'xing.de','xing.de','bing.com','swiss.ch','sbb.ch','sbb.ch','sbb.ch','my.ch'
        $test | ForEach-Object {
            $total += ($_.TcpTimeMs) + ($_.DigTimeMs)
        }

        div -Class "container" {

            p {
                "List some result from PsNetTools queries"
            }

            p {
                h2 "PsNetTools summary"
            }

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

            script -content {

                $data   = $test | Group-Object TcpDestination
                $yaxis  = $data | ForEach-Object {$_.Count}
                $xaxis  = $data.Name
                $colors = @("yellow","red","green","orange","blue")
                
                $dsp1   = New-PSHTMLChartPieDataSet -Data $yaxis -BackgroundColor $colors
                New-PSHTMLChart -type pie -DataSet $dsp1 -title "Count of Tcp Tests" -Labels $xaxis -CanvasID $PieCanvasID 

                $data   = Format-MWADataSet -Object $test #| Group-Object TimeMs
                $yaxis  = $data.TcpTimeMs
                $xaxis  = $data.Name
                $dsb1 = New-PSHTMLChartBarDataSet -Data $yaxis -label "TcpTimeMs" -backgroundColor 'blue' -hoverBackgroundColor 'magenta' -borderColor 'black' -hoverBorderColor 'black'
                
                $yaxis  = $data.DigTimeMs
                $xaxis  = $data.Name
                $dsb2 = New-PSHTMLChartBarDataSet -Data $yaxis -label "DigTimeMs" -backgroundColor 'green' -hoverBackgroundColor 'red' -borderColor 'black' -hoverBorderColor 'black'
                
                New-PSHTMLChart -type bar -DataSet @($dsb1, $dsb2) -title "Time in milliseconds" -Labels $xaxis -CanvasID $BarCanvasID 

                $data   = $test | Group-Object TcpStatusDescription
                $yaxis  = $data | ForEach-Object {$_.Count}
                $xaxis  = $data.Name
                $colors = @("CYAN","MAGENTA","YELLOW ","BLACK")

                $dsd1 = New-PSHTMLChartDoughnutDataSet -Data $yaxis -backgroundcolor $colors -hoverbackgroundColor $Colors
                New-PSHTMLChart -Type doughnut -DataSet $dsd1 -title "Amount of Tcp Results" -Labels $xaxis -CanvasID $DoughnutCanvasID 

            }
        
            p {
                h2 "PsNetTools details"
            }

            Table -Class "table table-responsive table-sm table-hover" -content {

                Thead -Class "thead-dark" {

                    Th {"TimeStamp"}
                    Th {"Tcp-/Dig Test"}
                    Th {"TcpPort"}
                    Th {"Target"}
                    Th {"IpV4Address"}
                    Th {"IpV6Address"}
                    Th {"StatusDescription"}
                    Th {"TcpTimeMs"}
                    Th {"DigTimeMs"}

                }

                Tbody {

                    $test | Sort-Object TcpTimeMS -Descending | ForEach-Object {

                        tr {
                            td {$_.TcpTimeStamp}
                            td {"$($_.TcpSucceeded)/$($_.DigSucceeded)"}
                            td {$_.TcpPort}
                            td {$_.TcpDestination}
                            td {
                                if($_.DigSucceeded){
                                    if($_.DigIpV4Address){
                                        foreach($item in $_.DigIpV4Address){
                                            $output += "$($item), "
                                        }
                                        if($output.EndsWith(', ')){$output.TrimEnd(', ')}
                                    }
                                }
                                else{'Dig Test failed'}
                            }
                            td {
                                if($_.DigSucceeded){
                                    if($_.DigIpV6Address){
                                        $_.DigIpV6Address
                                    }
                                }
                                else{'Dig Test failed'}
                            }
                            td {$_.TcpStatusDescription}
                            td {$_.TcpTimeMs}
                            td {$_.DigTimeMs}
                        }

                    }

                }

            }

            p -Class "font-weight-bold" {
                "The query for these {0} targets took a total of {1} milliseconds." -f $($test.count), $($total)
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