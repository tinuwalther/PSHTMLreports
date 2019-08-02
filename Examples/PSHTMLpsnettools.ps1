<#
    https://getbootstrap.com/
#>

#region Modules
if(-not(Get-Module -Name PSHTML)){
    Import-Module PSHTML
}

if(-not(Get-Module -Name PsNetTools)){
    Import-Module PsNetTools
}
#endregion

#region Data
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

$test = Get-MWADataSet -Destination 'xing.de','xing.de','bing.com','swiss.ch','sbb.ch','sbb.ch','sbb.ch','my.ch'
#endregion

#region Variables
$PieCanvasID         = "piecanvas"
$DoughnutCanvasID    = "Doughnutcanvas"
$BarCanvasID         = "barcanvas"
#endregion

#region header
$HeaderTitle        = "PSHTML-PsNetTools"
$HeaderCaption1     = "Combined PSHTML and PsNetTools report"
#endregion

#region body
$BodyDescription    = "List some result from PsNetTools queries"
#endregion

#region diagrams
$BodyCaptionDiagram = "PsNetTools summary"

#diagram left
$DiagramTitleLeft   = "Count of Tcp Tests"
$DiagramCaptionLeft = "Test Destination"
$DiagramLeft        = $test | Group-Object TcpDestination
$yaxisleft          = $DiagramLeft | ForEach-Object {$_.Count}
$xaxisleft          = $DiagramLeft.Name
$colorsleft         = @("yellow","red","green","orange","blue")

#diagram middle
$DiagramTitleMiddle   = "Time in milliseconds"
$DiagramCaptionMiddle = "Test Time"
$DiagramMiddle        = Format-MWADataSet -Object $test #| Group-Object TimeMs
$LabelMiddle1         = "TcpTimeMs"
$yaxisMiddle1         = $DiagramMiddle.TcpTimeMs
$LabelMiddle2         = "DigTimeMs"
$yaxisMiddle2         = $DiagramMiddle.DigTimeMs
$xaxisMiddle          = $DiagramMiddle.Name

#diagram right
$DiagramTitleRight   = "Count of Tcp Tests"
$DiagramCaptionRight = "Test Results"
$DiagramRight        = $test | Group-Object TcpStatusDescription
$yaxisRight          = $DiagramRight | ForEach-Object {$_.Count}
$xaxisRight          = $DiagramRight.Name
$colorsRight         = @("CYAN","MAGENTA","YELLOW ","BLACK")

#endregion

#region table
$BodyCaptionTable   = "PsNetTools details"

$TableClasses = "table table-responsive table-sm table-hover"
$TableHeaders = "thead-light"
$columns      = @('TcpTimeStamp','TcpSucceeded','DigSucceeded','TcpPort','TcpDestination','DigIpV4Address','DigIpV6Address','TcpStatusDescription','TcpTimeMs','DigTimeMs')

$topNav = a -Class "btn btn-outline-primary btn-sm" -href "#Summary" "Summary" -Attributes @{"role"="button"}
#endregion

#region footer
#endregion


$HTML = html {

    head{

        title $HeaderTitle
        Write-PSHTMLAsset -Name Jquery
        Write-PSHTMLAsset -Name BootStrap
        Write-PSHTMLAsset -Name Chartjs

        div -Class "container" {

            p -Class "border" {
                h1 $HeaderCaption1
            }

        }
    } 

    body{

        $test | ForEach-Object {
            $total += ($_.TcpTimeMs) + ($_.DigTimeMs)
        }

        div -Class "container" {

            p {
                $BodyDescription
            }

            #Diagrams
            p {
                h2 $BodyCaptionDiagram -id "Summary"
            }

            div -Class "row align-items-center" {

                div -Class "col-sm" {
                    canvas -Height 300px -Width 300px -Id $PieCanvasID {}
                    p {$DiagramCaptionLeft}
                }
                div -Class "col-sm" {
                    canvas -Height 300px -Width 300px -Id $BarCanvasID {}
                    p {$DiagramCaptionMiddle}
                }
                div -Class "col-sm" {
                    canvas -Height 300px -Width 300px -Id $DoughnutCanvasID {}
                    p {$DiagramCaptionRight}
                }

            }
            script -content {

                #Pie Chart
                $dsp1   = New-PSHTMLChartPieDataSet -Data $yaxisleft -BackgroundColor $colorsleft
                New-PSHTMLChart -type pie -DataSet $dsp1 -title $diagramtitleleft -Labels $xaxisleft -CanvasID $PieCanvasID 

                #Bar Chart
                $dsb1 = New-PSHTMLChartBarDataSet -Data $yaxisMiddle1 -label $LabelMiddle1 -backgroundColor 'blue' -hoverBackgroundColor 'magenta' -borderColor 'black' -hoverBorderColor 'black'
                $dsb2 = New-PSHTMLChartBarDataSet -Data $yaxisMiddle2 -label $LabelMiddle2 -backgroundColor 'green' -hoverBackgroundColor 'red' -borderColor 'black' -hoverBorderColor 'black'
                New-PSHTMLChart -type bar -DataSet @($dsb1, $dsb2) -title $DiagramTitleMiddle -Labels $xaxisMiddle -CanvasID $BarCanvasID 

                #Doughnut Chart
                $dsd1 = New-PSHTMLChartDoughnutDataSet -Data $yaxisRight -backgroundcolor $colorsRight -hoverbackgroundColor $ColorsRight
                New-PSHTMLChart -Type doughnut -DataSet $dsd1 -title $DiagramTitleRight -Labels $xaxisRight -CanvasID $DoughnutCanvasID 

            }
        
            #Navigation
            ul -Class "nav nav-tabs" {
                li -Class "nav-item" {
                    a -Class "nav-link active" -href "#Summary" "$($BodyCaptionDiagram)"
                }
                li -Class "nav-item" {
                    a -Class "nav-link" -href "#navlink2" "$($BodyCaptionTable)"
                }
            }

            #Table
            p {
                h2 $BodyCaptionTable -Id "navlink2"
            }
            ConvertTo-PSHtmlTable -Object $test -Properties $columns -TableClass $TableClasses -TheadClass $TableHeaders

            p -Class "font-weight-bold" {
                "The query for these {0} targets took a total of {1} milliseconds." -f $($test.count), $($total)
            }
            p {
                $topNav
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