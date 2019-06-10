<#
    https://getbootstrap.com/
#>

function Get-MWAProcess{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Int] $count
    )

    return Get-Process | Where-Object Name -ne 'Memory Compression' | `
        Sort-Object WorkingSet64 -Descending | `
        Select-Object -First $count | `
        Select-Object Id,Name,Starttime,Path,PrivateMemorySize64,WorkingSet64
}

function Format-MWADataSet{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [Object] $process
    )

    $array = foreach ($item in $process) {
        [pscustomobject]@{
            PID                   = $item.Id
            Name                  = $item.Name
            Starttime             = $item.Starttime
            Path                  = $item.Path
            PrivateMemorySize64KB = ([math]::Round(($item.PrivateMemorySize64)/1kb))
            WorkingSet64KB        = ([math]::Round(($item.WorkingSet64)/1kb))
            PrivateMemorySize64MB = ([math]::Round(($item.PrivateMemorySize64)/1mb))
            WorkingSet64MB        = ([math]::Round(($item.WorkingSet64)/1mb))
        }
    }
    return $array
}

if(-not(Get-Module -Name PSHTML)){
    Import-Module PSHTML
}

$PieCanvasID      = "piecanvas"
$DoughnutCanvasID = "Doughnutcanvas"
$BarCanvasID      = "barcanvas"

$HTML = html {

    head{

        title "PSHTML-Process"
        Write-PSHTMLAsset -Name Jquery
        Write-PSHTMLAsset -Name BootStrap
        Write-PSHTMLAsset -Name Chartjs

        div -Class "container" {
            p -Class "border" {
                h1 "PSHTML process report"
            }
        }
    } 

    body{

        $process = Get-MWAProcess -count 5
        $process | ForEach-Object {
            $total += $_.WorkingSet64
        }

        div -Class "container" {

            p {
                "List $($process.count) most resource-intensive process"
            }

            Form -action "/_blank" -method Post -Content {

                input -type "text" -name "computername" -value "localhost"
                input -type "submit" -name "submit" -value "Submit"

            } -enctype "application/x-www-form-urlencoded"

            p {
                h2 "Summary"
            }

            div -Class "row align-items-center" {
                div -Class "col-sm" -Style "allign-center" {
                    canvas -Height 300px -Width 300px -Id $PieCanvasID {}
                }
                div -Class "col-sm" -Style "allign-center" {
                    canvas -Height 300px -Width 300px -Id $BarCanvasID {}
                }
                div -Class "col-sm" -Style "allign-center" {
                    canvas -Height 300px -Width 300px -Id $DoughnutCanvasID {}
                }
            }

            script -content {

                $data   = $process | Group-Object Name
                $counts = $data | ForEach-Object {$_.Count}
                $labels = $data.Name
                $colors = @("yellow","red","green","orange","blue")
                
                $dsp1   = New-PSHTMLChartPieDataSet -Data $counts -BackgroundColor $colors
                New-PSHTMLChart -type pie -DataSet $dsp1 -title "Count of most resource-intensive process" -Labels $labels -CanvasID $PieCanvasID 

                $bardata   = Format-MWADataSet -process $process
                $barcounts = $bardata.WorkingSet64MB
                $barlabels = $bardata.Name

                $dsb1 = New-PSHTMLChartBarDataSet -Data $barcounts -label "WorkingSet64 in MB" -backgroundColor 'blue' -hoverBackgroundColor 'red' -borderColor 'red' -hoverBorderColor 'red'
                New-PSHTMLChart -type bar -DataSet $dsb1 -title "Amount of allocated memory in MB" -Labels $barlabels -CanvasID $BarCanvasID 

                $dsd1 = New-PSHTMLChartDoughnutDataSet -Data $barcounts -backgroundcolor $colors -hoverbackgroundColor $Colors
                New-PSHTMLChart -Type doughnut -DataSet $dsd1 -title "Amount of allocated memory in MB" -Labels $barlabels -CanvasID $DoughnutCanvasID 

            }
        
            p {
                h2 "Details"
            }

            Table -Class "table table-responsive table-sm table-hover" -content {

                Thead -Class "thead-dark" {

                    Th {"PID"}
                    Th {"Name"}
                    Th {"Path"}
                    Th {"StartTime"}
                    Th {"Commit (KB)"}
                    Th {"Working Set (KB)"}

                }

                Tbody {

                    Format-MWADataSet -process $process | ForEach-Object {

                        tr {
                            td {$_.PID}
                            td {$_.Name}
                            td {$_.Path}
                            td {$_.StartTime}
                            td {"{0:N0}" -f ($_.PrivateMemorySize64KB)}
                            td {"{0:N0}" -f ($_.WorkingSet64KB)}
                        }

                    }

                }

            }

            p -Class "font-weight-bold" {
                "This {0} processes use {1:N0} MB Memory" -f $($process.count), ([math]::Round(($total)/1mb))
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