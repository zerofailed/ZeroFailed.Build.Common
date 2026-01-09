# <copyright file="ConvertFrom-CoberturaXml.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
    Converts a Cobertura XML coverage report into a formatted Markdown summary report.
.DESCRIPTION
    This function takes a Cobertura XML coverage report and converts it into a comprehensive
    Markdown document with tables, metrics, and visual indicators. It efficiently handles
    large XML files (100MB+) using streaming processing and provides multiple aggregation
    levels including package, class, and method coverage details.
.EXAMPLE
    PS C:\> ConvertFrom-CoberturaXml -Path "./coverage.xml" -OutputPath "./coverage-report.md"
    
    Converts the coverage report and saves it as a Markdown file.
.EXAMPLE
    PS C:\> ConvertFrom-CoberturaXml -Path "./coverage.xml" -IncludeMethodDetails -MinimumCoverage 80
    
    Generates a detailed report including method-level details and highlights items below 80% coverage.
.EXAMPLE
    PS C:\> $markdown = ConvertFrom-CoberturaXml -Path "./large-coverage.xml" -SummaryOnly
    
    Processes a large file and returns only a summary report as a string.
.PARAMETER Path
    The path to the Cobertura XML coverage report file.
.PARAMETER OutputPath
    Optional path where the Markdown report should be saved. If not specified, the report is returned as a string.
.PARAMETER IncludeMethodDetails
    Include detailed method-level coverage information in the report.
.PARAMETER SummaryOnly
    Generate only a summary report without detailed breakdowns.
.PARAMETER MinimumCoverage
    Highlight packages/classes with coverage below this threshold (default: 70).
.PARAMETER Title
    Custom title for the coverage report (default: "Code Coverage Report").
.OUTPUTS
    Returns the Markdown content as a string if OutputPath is not specified.
#>
function ConvertFrom-CoberturaXml
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Path,
        
        [Parameter()]
        [string] $OutputPath,
        
        [Parameter()]
        [switch] $IncludeMethodDetails,
        
        
        [Parameter()]
        [switch] $SummaryOnly,
        
        [Parameter()]
        [double] $MinimumCoverage = 70.0,
        
        [Parameter()]
        [string] $Title = "Code Coverage Report"
    )

    Write-Verbose "Starting conversion of Cobertura XML: $Path"
    
    try {
        # Read the coverage data using streaming
        Write-Verbose "Reading coverage data from XML..."
        $coverageData = Read-CoberturaXmlStream -Path $Path
        
        # Generate the Markdown report
        Write-Verbose "Generating Markdown report..."
        $markdown = _generateMarkdownReport -CoverageData $coverageData -Title $Title -IncludeMethodDetails:$IncludeMethodDetails -SummaryOnly:$SummaryOnly -MinimumCoverage $MinimumCoverage
        
        # Output to file if specified, otherwise return string
        if ($OutputPath) {
            Write-Verbose "Writing report to: $OutputPath"
            $markdown | Out-File -FilePath $OutputPath -Encoding utf8
            Write-Information "Coverage report written to: $OutputPath" -InformationAction Continue
        } else {
            return $markdown
        }
    }
    catch {
        throw "Error converting Cobertura XML to Markdown: $($_.Exception.Message)"
    }
}

# Internal function to generate the complete Markdown report
function _generateMarkdownReport {
    [CmdletBinding()]
    param (
        [hashtable] $CoverageData,
        [string] $Title,
        [bool] $IncludeMethodDetails,
        [bool] $SummaryOnly,
        [double] $MinimumCoverage
    )
    
    $markdown = @()
    
    # Report header
    $markdown += "# $Title"
    $markdown += ""
    $markdown += "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    if ($CoverageData.CoverageInfo.Timestamp) {
        $reportDate = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$CoverageData.CoverageInfo.Timestamp).ToString('yyyy-MM-dd HH:mm:ss')
        $markdown += "Coverage Date: $reportDate"
    }
    $markdown += ""
    
    # Executive summary
    $markdown += "## Executive Summary"
    $markdown += ""
    $summary = New-CoverageSummary -CoverageInfo $CoverageData.CoverageInfo -PackageCount $CoverageData.Packages.Count
    $markdown += $summary
    $markdown += ""
    
    # Overall metrics table
    $markdown += "## Overall Coverage Metrics"
    $markdown += ""
    $overallTable = New-CoverageMarkdownTable -Data @($CoverageData.CoverageInfo) -Type 'Overall' -MinimumCoverage $MinimumCoverage
    $markdown += $overallTable
    $markdown += ""
    
    if (-not $SummaryOnly) {
        # Package-level breakdown
        if ($CoverageData.Packages.Count -gt 0) {
            $markdown += "## Package Coverage"
            $markdown += ""
            $packageTable = New-CoverageMarkdownTable -Data $CoverageData.Packages -Type 'Package' -MinimumCoverage $MinimumCoverage
            $markdown += $packageTable
            $markdown += ""
            
            # Detailed package analysis
            foreach ($package in $CoverageData.Packages) {
                if ($package.Classes.Count -gt 0) {
                    $markdown += "### Package: $($package.Name)"
                    $markdown += ""
                    
                    # Class-level breakdown for this package
                    $classTable = New-CoverageMarkdownTable -Data $package.Classes -Type 'Class' -MinimumCoverage $MinimumCoverage
                    $markdown += $classTable
                    $markdown += ""
                    
                    if ($IncludeMethodDetails) {
                        # Method-level details
                        foreach ($class in $package.Classes) {
                            if ($class.Methods.Count -gt 0) {
                                $markdown += "#### Class: $($class.Name)"
                                $markdown += ""
                                $methodTable = New-CoverageMarkdownTable -Data $class.Methods -Type 'Method' -MinimumCoverage $MinimumCoverage
                                $markdown += $methodTable
                                $markdown += ""
                            }
                        }
                    }
                }
            }
        }
        
        # Coverage insights
        $markdown += "## Coverage Insights"
        $markdown += ""
        $insights = _generateCoverageInsights -CoverageData $CoverageData -MinimumCoverage $MinimumCoverage
        $markdown += $insights
        $markdown += ""
    }
    
    # Footer
    $markdown += "---"
    $markdown += ""
    $markdown += "*Report generated using [ZeroFailed](https://github.com/zerofailed/ZeroFailed.DevOps.Common)*"
    
    return $markdown -join "`n"
}

# Internal function to generate coverage insights and recommendations
function _generateCoverageInsights {
    [CmdletBinding()]
    param (
        [hashtable] $CoverageData,
        [double] $MinimumCoverage
    )
    
    $insights = @()
    
    # Calculate key statistics
    $totalPackages = $CoverageData.Packages.Count
    $lowCoveragePackages = @($CoverageData.Packages | Where-Object { $_.LineRate * 100 -lt $MinimumCoverage })
    $highCoveragePackages = @($CoverageData.Packages | Where-Object { $_.LineRate * 100 -ge 90 })
    
    $totalClasses = ($CoverageData.Packages | ForEach-Object { $_.Classes.Count } | Measure-Object -Sum).Sum
    $lowCoverageClasses = @($CoverageData.Packages | ForEach-Object { $_.Classes } | Where-Object { $_.LineRate * 100 -lt $MinimumCoverage })
    
    # Overall assessment
    $overallCoverage = $CoverageData.CoverageInfo.LineRate * 100
    if ($overallCoverage -ge 90) {
        $insights += "✅ **Excellent coverage!** Overall line coverage is $($overallCoverage.ToString('F1'))%"
    } elseif ($overallCoverage -ge $MinimumCoverage) {
        $insights += "✔️ **Good coverage.** Overall line coverage is $($overallCoverage.ToString('F1'))%"
    } else {
        $insights += "⚠️ **Coverage needs improvement.** Overall line coverage is $($overallCoverage.ToString('F1'))%, below target of $($MinimumCoverage)%"
    }
    $insights += ""
    
    # Package insights
    if ($totalPackages -gt 0) {
        $insights += "### Package Analysis"
        $insights += ""
        $insights += "- **Total Packages:** $totalPackages"
        $insights += "- **High Coverage (≥90%):** $($highCoveragePackages.Count) packages"
        $insights += "- **Low Coverage (<$($MinimumCoverage)%):** $($lowCoveragePackages.Count) packages"
        $insights += ""
        
        if ($lowCoveragePackages.Count -gt 0) {
            $insights += "**Packages requiring attention:**"
            foreach ($package in $lowCoveragePackages | Sort-Object LineRate | Select-Object -First 5) {
                $coverage = ($package.LineRate * 100).ToString('F1')
                $insights += "- $($package.Name)` - $coverage% coverage"
            }
            $insights += ""
        }
    }
    
    # Class insights
    if ($totalClasses -gt 0) {
        $insights += "### Class Analysis"
        $insights += ""
        $insights += "- **Total Classes:** $totalClasses"
        $insights += "- **Low Coverage Classes:** $($lowCoverageClasses.Count)"
        $insights += ""
        
        if ($lowCoverageClasses.Count -gt 0 -and $lowCoverageClasses.Count -le 10) {
            $insights += "**Classes requiring attention:**"
            foreach ($class in $lowCoverageClasses | Sort-Object LineRate | Select-Object -First 10) {
                $coverage = ($class.LineRate * 100).ToString('F1')
                $insights += "- $($class.Name)` - $coverage% coverage"
            }
            $insights += ""
        }
    }
    
    # Recommendations
    $insights += "### Recommendations"
    $insights += ""
    if ($overallCoverage -lt $MinimumCoverage) {
        $insights += "1. **Priority:** Focus on packages and classes with coverage below $($MinimumCoverage)%"
        $insights += "2. **Target:** Aim to increase overall coverage to at least $($MinimumCoverage)%"
    }
    if ($CoverageData.CoverageInfo.BranchRate * 100 -lt $overallCoverage) {
        $branchCoverage = ($CoverageData.CoverageInfo.BranchRate * 100).ToString('F1')
        $insights += "3. **Branch Coverage:** Consider improving branch coverage ($branchCoverage%) by adding tests for conditional logic"
    }
    $insights += "4. **Maintenance:** Review and maintain test coverage as code evolves"
    
    return $insights
}