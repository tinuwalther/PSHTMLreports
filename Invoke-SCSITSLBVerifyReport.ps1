
function Invoke-SCSITSLBVerifyReport{

    <#

    .Synopsis
    ITSLB Verify Report

    .DESCRIPTION
    ITSLB Verify Patching, Sophia Upload, and Malware Protection Report

    .EXAMPLE
    Example of how to use this cmdlet

    .NOTES
    start firefox 'https://getbootstrap.com/docs/4.3/getting-started/introduction/'
    start firefox 'https://pshtml.readthedocs.io/en/latest/'

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        $HTMLReport
    )

    begin{

        $function = $($MyInvocation.MyCommand.Name)

        <#
        #region Modules
        if(-not(Get-Module -Name PSHTML)){
            Import-Module PSHTML
        }
        #endregion
        #>

        function Format-DataSetFromJson{
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true)]
                [String] $file
            )
            $Result = Get-Content $($file) | ConvertFrom-Json

            $array = foreach($item in $Result){
                $ci = $item.CIName.substring(0,8)
                $rn = $item.RuleName.substring(0,8)
                if($ci -ne $rn){
                    [PSCustomObject]@{
                        VerifyTimeStamp = $item.VerifyTimeStamp
                        CIName          = $item.CIName
                        RuleName        = $item.RuleName
                        RuleState       = $item.RuleState
                        ActualValue     = $item.ActualValue
                        Instance        = $item.Instance
                        DeviceName      = $item.DeviceName
                        IPAddresses     = $item.IPAddresses[0]
                        NetBIOSDomain   = $item.NetBIOSDomain
                    }
                }
            }
            return $array
        }

    }

    process{

    $Root = Split-Path -parent $PSCommandPath

    #region Data
    $PatchingJsonFile = Get-ChildItem -Path "$($Root)\Output" -Filter '*Verify-ITSLB-Patching*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if($PatchingJsonFile){
        $FormatedDataLeft     = Format-DataSetFromJson -file $PatchingJsonFile.FullName | Sort-Object DeviceName
        $PatchingRuleName     = $($FormatedDataLeft | Select-Object -First 1 | Select-Object -ExpandProperty RuleName)
        $PatchingNonCompliant = $FormatedDataLeft | Where-Object RuleState -eq NonCompliant
        $PatchingCompliant    = $FormatedDataLeft | Where-Object RuleState -eq Compliant
    }

    $SophiaJsonFile = Get-ChildItem -Path "$($Root)\Output" -Filter '*Verify-ITSLB-Sophia*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if($SophiaJsonFile){
        $FormatedDataMiddle = Format-DataSetFromJson -file $SophiaJsonFile.FullName | Sort-Object DeviceName
        $SophiaRuleName     = $($FormatedDataMiddle | Select-Object -First 1 | Select-Object -ExpandProperty RuleName)
        $SophiaNonCompliant = $FormatedDataMiddle | Where-Object RuleState -eq NonCompliant
        $SophiaCompliant    = $FormatedDataMiddle | Where-Object RuleState -eq Compliant
    }

    $MalwareJsonFile = Get-ChildItem -Path "$($Root)\Output" -Filter '*Verify-ITSLB-Malware*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if($MalwareJsonFile){
        $FormatedDataRight = Format-DataSetFromJson -file $MalwareJsonFile.FullName | Sort-Object DeviceName
        $MalwareRuleName     = $($FormatedDataRight | Select-Object -First 1 | Select-Object -ExpandProperty RuleName)
        $MalwareNonCompliant = $FormatedDataRight | Where-Object RuleState -eq NonCompliant
        $MalwareCompliant    = $FormatedDataRight | Where-Object RuleState -eq Compliant
    }
    #endregion

    #region header
    $HeaderTitle          = "ITSLB-Verify"
    #endregion

    #region body
    $BodyCaption1         = $HeaderTitle + " Report"
    $BodyDescription      = "List ITSLB compliance results about Windows Updates, ITSLB Upload and Malware Protection from $(Get-Date ($PatchingJsonFile.LastWriteTime) -f 'yyyy-MM-dd')"
    $BodyCaptionDiagram   = "Summary"
    $BodyCaptionTable     = "Details"
    #endregion 

    #region diagrams

    #diagram left
    $DoughnutCanvasLeft   = "Doughnutcanvas001"
    $DiagramTitleLeft     = "PMGT - Windows Updates [$($FormatedDataLeft.count) Objects]"
    $DiagramCaptionLeft   = "LastInstalled Hotfix within 45 days"
    $DiagramLeft          = $FormatedDataLeft | Group-Object RuleState
    $yaxisLeft            = $DiagramLeft | ForEach-Object {$_.Count}
    $xaxisLeft            = $DiagramLeft.Name
    $colorsLeft           = @("green","red","yellow")

    #diagram middle
    $DoughnutCanvasMiddle = "Doughnutcanvas002"
    $DiagramTitleMiddle   = "BPSC - ITSLB Upload [$($FormatedDataMiddle.count) Objects]"
    $DiagramCaptionMiddle = "Sophia Report Upload within 7 days"
    $DiagramMiddle        = $FormatedDataMiddle | Group-Object RuleState
    $yaxisMiddle          = $DiagramMiddle | ForEach-Object {$_.Count}
    $xaxisMiddle          = $DiagramMiddle.Name
    $colorsMiddle         = @("green","red","yellow")

    #diagram right
    $DoughnutCanvasRight  = "Doughnutcanvas003"
    $DiagramTitleRight    = "MWP - Malware Protection [$($FormatedDataRight.count) Objects]"
    $DiagramCaptionRight  = "Malware Pattern within 48 hours"
    $DiagramRight         = $FormatedDataRight | Group-Object RuleState
    $yaxisRight           = $DiagramRight | ForEach-Object {$_.Count}
    $xaxisRight           = $DiagramRight.Name
    $colorsRight          = @("green","red","yellow")
    #endregion

    #region table
    $TableClasses = "table table-sm table-hover"
    $TableHeaders = "thead-light"

    $PatchingBodyCaptionTable = "Patching"
    $SophiaBodyCaptionTable   = "Sophia"
    $MalwareBodyCaptionTable  = "Malware"

    $Column1 = "DeviceName"
    $Column2 = "NetBIOSDomain"
    $Column3 = "IPAddresses"
    $Column4 = "RuleName"
    $Column5 = "RuleState"
    $Column6 = "ActualValue"

    $topNav = a -Class "btn btn-outline-primary btn-sm" -href "#Summary" "Summary" -Attributes @{"role"="button"}
    #endregion

    #region footer
    #endregion

    #region HTML
    $HTML = html {

        head{

            title $HeaderTitle
            Write-PSHTMLAsset -Name Jquery
            Write-PSHTMLAsset -Name BootStrap
            Write-PSHTMLAsset -Name Chartjs
        } 

        body{

            div -Class "container" {

                div -Class "jumbotron" -id "Summary" -Style "background-color:#66b5ff" {
                    div -Class "container" {
                        h1 -Class "display-4 font-weight-bold" -Style "color:white" { 
                            $BodyCaption1
                        }
                        p -Class "lead" -Style "color:white" {
                            $BodyDescription
                        }
                    }
                }

                #Diagrams
                p {
                    h2 $BodyCaptionDiagram
                }

                div -Class "row align-items-center" {
                    div -Class "col-sm" {
                        canvas -Height 300px -Width 300px -Id $DoughnutCanvasLeft {}
                        p {$DiagramCaptionLeft}
                    }
                    div -Class "col-sm" {
                        canvas -Height 300px -Width 300px -Id $DoughnutCanvasMiddle {}
                        p {$DiagramCaptionMiddle}
                    }
                    div -Class "col-sm" {
                        canvas -Height 300px -Width 300px -Id $DoughnutCanvasRight {}
                        p {$DiagramCaptionRight}
                    }
                }

                script -content {

                    #Doughnut Chart left
                    $dsdleft = New-PSHTMLChartDoughnutDataSet -Data $yaxisleft -backgroundcolor $colorsLeft -hoverbackgroundColor $ColorsLeft
                    New-PSHTMLChart -Type doughnut -DataSet $dsdleft -title $DiagramTitleLeft -Labels $xaxisLeft -CanvasID $DoughnutCanvasLeft 

                    #Doughnut Chart middle
                    $dsdmiddle = New-PSHTMLChartDoughnutDataSet -Data $yaxisMiddle -backgroundcolor $colorsMiddle -hoverbackgroundColor $ColorsMiddle
                    New-PSHTMLChart -Type doughnut -DataSet $dsdmiddle -title $DiagramTitleMiddle -Labels $xaxisMiddle -CanvasID $DoughnutCanvasMiddle 

                    #Doughnut Chart right
                    $dsdright = New-PSHTMLChartDoughnutDataSet -Data $yaxisRight -backgroundcolor $colorsRight -hoverbackgroundColor $ColorsRight
                    New-PSHTMLChart -Type doughnut -DataSet $dsdright -title $DiagramTitleRight -Labels $xaxisRight -CanvasID $DoughnutCanvasRight 

                }
                
                #Navigation
                ul -Class "nav nav-tabs" {
                    li -Class "nav-item" {
                        a -Class "nav-link active" -href "#navlink1" "$($PatchingBodyCaptionTable) NonCompliant"
                    }
                    li -Class "nav-item" {
                        a -Class "nav-link" -href "#navlink2" "$($PatchingBodyCaptionTable) Compliant"
                    }
                    li -Class "nav-item" {
                        a -Class "nav-link" -href "#navlink3" "$($SophiaBodyCaptionTable) NonCompliant"
                    }
                    li -Class "nav-item" {
                        a -Class "nav-link" -href "#navlink4" "$($SophiaBodyCaptionTable) Compliant"
                    }
                    li -Class "nav-item" {
                        a -Class "nav-link" -href "#navlink5" "$($MalwareBodyCaptionTable) NonCompliant"
                    }
                    li -Class "nav-item" {
                        a -Class "nav-link" -href "#navlink6" "$($MalwareBodyCaptionTable) Compliant"
                    }
                }

                p {
                    h2 $BodyCaptionTable
                }

                #Table Patching NonCompliant
                if($PatchingNonCompliant){
                    p {
                        h3 "$($PatchingBodyCaptionTable) NonCompliant" -Id "navlink1"
                    }
                    div -class "table-responsive" {

                        ConvertTo-PSHtmlTable -Object $PatchingNonCompliant -Properties $Column1,$Column2,$Column3,$Column4,$Column5,$Column6 -TableClass $TableClasses -TheadClass $TableHeaders
                        
                        <#
                        Table -Class "table table-sm table-hover" -content {
                            #Table column heading
                            Thead -Class "thead-dark" {
                                Th { $Column1 }
                                Th { $Column2 }
                                Th { $Column3 }
                                Th { $Column4 }
                                Th { $Column5 }
                                Th { $Column6 }
                            }
                            Tbody {
                                $PatchingNonCompliant | Sort-Object DeviceName | ForEach-Object {
                                    tr {
                                        td { $_.$Column1 }
                                        td { $_.$Column2 }
                                        td { $_.$Column3 }
                                        td { $_.$Column4 }
                                        td { $_.$Column5 }
                                        td { $_.$Column6 }
                                    }
                                }
                            }
                        }
                        #>

                    }
                    p {
                        $topNav
                    }
                }

                #Table Patching Compliant
                if($PatchingCompliant){
                    p {
                        h3 "$($PatchingBodyCaptionTable) Compliant" -Id "navlink2"
                    }
                    div -class "table-responsive" {
                        ConvertTo-PSHtmlTable -Object $PatchingCompliant -Properties $Column1,$Column2,$Column3,$Column4,$Column5,$Column6 -TableClass $TableClasses -TheadClass $TableHeaders
                    }
                    p {
                        $topNav
                    }
                }

                #Table Sophia NonCompliant
                if($SophiaNonCompliant){
                    p {
                        h3 "$($SophiaBodyCaptionTable) NonCompliant" -Id "navlink3"
                    }
                    div -class "table-responsive" {
                        ConvertTo-PSHtmlTable -Object $SophiaNonCompliant -Properties $Column1,$Column2,$Column3,$Column4,$Column5,$Column6 -TableClass $TableClasses -TheadClass $TableHeaders
                    }
                    p {
                        $topNav
                    }
                }

                #Table Sophia Compliant
                if($SophiaCompliant){
                    p {
                        h3 "$($SophiaBodyCaptionTable) Compliant" -Id "navlink4"
                    }
                    div -class "table-responsive" {
                        ConvertTo-PSHtmlTable -Object $SophiaCompliant -Properties $Column1,$Column2,$Column3,$Column4,$Column5,$Column6 -TableClass $TableClasses -TheadClass $TableHeaders
                    }
                    p {
                        $topNav
                    }
                }

                #Table Malware NonCompliant
                if($MalwareNonCompliant){
                    p {
                        h3 "$($MalwareBodyCaptionTable) NonCompliant" -Id "navlink5"
                    }
                    div -class "table-responsive" {
                        ConvertTo-PSHtmlTable -Object $MalwareNonCompliant -Properties $Column1,$Column2,$Column3,$Column4,$Column5,$Column6 -TableClass $TableClasses -TheadClass $TableHeaders
                    }
                    p {
                        $topNav
                    }
                }

                #Table Malware Compliant
                if($MalwareCompliant) {
                    p {
                        h3 "$($PatchingBodyCaptionTable) Compliant" -Id "navlink6"
                    }
                    div -class "table-responsive" {
                        ConvertTo-PSHtmlTable -Object $MalwareCompliant -Properties $Column1,$Column2,$Column3,$Column4,$Column5,$Column6 -TableClass $TableClasses -TheadClass $TableHeaders
                    }
                    p {
                        $topNav
                    }
                }

            }

        }

        Footer {

            div -Class "container" {
                p {
                    "Copyright © $(Get-Date -f 'yyyy') Swisscom (Schweiz) AG | Created with " 
                    a "PSHTML" -href "https://github.com/Stephanevg/PSHTML" -Target "_blank" 
                }
            }

        }
    }
    #endregion

    }

    end{

        $TimeStamp = Get-Date -f 'yyyyMMdd-HHmmss'
        if($HTMLReport){
            $HTMLReport = "$($Root)\Output\$($HTMLReport)_$($TimeStamp).html"
        }
        else{
            $HTMLReport = "$($Root)\Output\$($function)_$($TimeStamp).html"
        }
        if(-not([String]::IsNullOrEmpty($Html))){
            $Html | Out-File -FilePath $HTMLReport -Encoding utf8
            #Start-Process $HTMLReport 
        }

    }

}

<# 
=====================================================

                FUNCTION SPLITTER

=====================================================
#>
