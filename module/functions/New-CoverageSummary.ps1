# <copyright file="New-CoverageSummary.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
    Creates an executive summary section for code coverage reports.
.DESCRIPTION
    This function generates a comprehensive executive summary that provides a high-level
    overview of code coverage metrics, key insights, and overall assessment of the
    codebase's test coverage. The summary is designed to give stakeholders a quick
    understanding of the current state of code coverage.
.EXAMPLE
    PS C:\> New-CoverageSummary -CoverageInfo $coverageData.CoverageInfo -PackageCount 15
    
    📊 **Overall Line Coverage:** ✅ 85.5% (855 of 1,000 lines covered)
    📈 **Branch Coverage:** ✔️ 78.2% (156 of 200 branches covered)
    📦 **Packages Analyzed:** 15
    🔧 **Code Complexity:** 🟢 4.2 (Low complexity)
.PARAMETER CoverageInfo
    The overall coverage information object containing metrics.
.PARAMETER PackageCount
    The total number of packages analyzed.
.PARAMETER Style
    The formatting style for percentages: Icon, Badge, ProgressBar, or Simple.
.PARAMETER IncludeRecommendations
    Include actionable recommendations in the summary.
.OUTPUTS
    Returns an array of strings representing the executive summary content.
#>
function New-CoverageSummary
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] $CoverageInfo,
        
        [Parameter(Mandatory=$true)]
        [int] $PackageCount,
        
        [Parameter()]
        [ValidateSet('Icon', 'Badge', 'ProgressBar', 'Simple')]
        [string] $Style = 'Icon',
        
        [Parameter()]
        [switch] $IncludeRecommendations
    )

    $summary = @()
    
    # Key metrics with visual indicators
    $lineMetrics = Format-CoverageMetrics -LineCoverage $CoverageInfo.LineRate -BranchCoverage $CoverageInfo.BranchRate -Complexity $CoverageInfo.Complexity -Style $Style
    
    # Main coverage metrics
    $summary += "📊 **Overall Line Coverage:** $($lineMetrics.Line) ($($CoverageInfo.LinesCovered) of $($CoverageInfo.LinesValid) lines covered)"
    
    if ($CoverageInfo.BranchesValid -gt 0) {
        $summary += "📈 **Branch Coverage:** $($lineMetrics.Branch) ($($CoverageInfo.BranchesCovered) of $($CoverageInfo.BranchesValid) branches covered)"
    }
    
    $summary += "📦 **Packages Analyzed:** $PackageCount"
    
    if ($CoverageInfo.Complexity -gt 0) {
        $complexityAssessment = _getComplexityAssessment $CoverageInfo.Complexity
        $summary += "🔧 **Code Complexity:** $($lineMetrics.Complexity) ($complexityAssessment)"
    }
    
    $summary += ""
    
    # Overall assessment
    $assessment = _generateOverallAssessment -CoverageInfo $CoverageInfo
    $summary += $assessment
    $summary += ""
    
    # Quick stats
    $summary += "### Quick Stats"
    $summary += ""
    $quickStats = _generateQuickStats -CoverageInfo $CoverageInfo -PackageCount $PackageCount
    $summary += $quickStats
    $summary += ""
    
    # Recommendations if requested
    if ($IncludeRecommendations) {
        $recommendations = _generateRecommendations -CoverageInfo $CoverageInfo
        if ($recommendations.Count -gt 0) {
            $summary += "### Key Recommendations"
            $summary += ""
            $summary += $recommendations
            $summary += ""
        }
    }
    
    return $summary
}

# Internal function to assess overall coverage quality
function _generateOverallAssessment {
    [CmdletBinding()]
    param (
        [hashtable] $CoverageInfo
    )
    
    $lineCoverage = $CoverageInfo.LineRate * 100
    $branchCoverage = $CoverageInfo.BranchRate * 100
    
    $assessment = @()
    
    # Overall quality assessment
    if ($lineCoverage -ge 90) {
        $assessment += "🎯 **Excellent Coverage!** Your codebase demonstrates strong test coverage with over 90% line coverage."
    } elseif ($lineCoverage -ge 80) {
        $assessment += "✅ **Good Coverage.** Your codebase has solid test coverage above 80%."
    } elseif ($lineCoverage -ge 70) {
        $assessment += "⚠️ **Moderate Coverage.** Test coverage is acceptable but has room for improvement."
    } elseif ($lineCoverage -ge 50) {
        $assessment += "🔶 **Low Coverage.** Significant gaps in test coverage that should be addressed."
    } else {
        $assessment += "🚨 **Critical Coverage Gap.** Test coverage is critically low and requires immediate attention."
    }
    
    # Branch coverage assessment
    if ($CoverageInfo.BranchesValid -gt 0) {
        $branchGap = $lineCoverage - $branchCoverage
        if ($branchGap -gt 10) {
            $assessment += "Branch coverage lags behind line coverage by $($branchGap.ToString('F1'))%, indicating missed conditional logic testing."
        } elseif ($branchCoverage -ge 80) {
            $assessment += "Branch coverage is strong, indicating good testing of conditional logic."
        }
    }
    
    return $assessment
}

# Internal function to generate quick statistics
function _generateQuickStats {
    [CmdletBinding()]
    param (
        [hashtable] $CoverageInfo,
        [int] $PackageCount
    )
    
    $stats = @()
    
    # Calculate ratios and percentages
    $lineCoverage = $CoverageInfo.LineRate * 100
    $branchCoverage = if ($CoverageInfo.BranchesValid -gt 0) { $CoverageInfo.BranchRate * 100 } else { 0 }
    
    $stats += "- **Lines of Code:** $($CoverageInfo.LinesValid.ToString('N0'))"
    $stats += "- **Covered Lines:** $($CoverageInfo.LinesCovered.ToString('N0'))"
    $stats += "- **Uncovered Lines:** $(($CoverageInfo.LinesValid - $CoverageInfo.LinesCovered).ToString('N0'))"
    
    if ($CoverageInfo.BranchesValid -gt 0) {
        $stats += "- **Total Branches:** $($CoverageInfo.BranchesValid.ToString('N0'))"
        $stats += "- **Covered Branches:** $($CoverageInfo.BranchesCovered.ToString('N0'))"
    }
    
    $stats += "- **Packages:** $PackageCount"
    
    if ($CoverageInfo.Complexity -gt 0) {
        $stats += "- **Average Complexity:** $($CoverageInfo.Complexity.ToString('F1'))"
    }
    
    # Coverage efficiency
    if ($CoverageInfo.LinesValid -gt 0) {
        $coverageEfficiency = ($CoverageInfo.LinesCovered / $CoverageInfo.LinesValid) * 100
        $stats += "- **Coverage Efficiency:** $($coverageEfficiency.ToString('F1'))%"
    }
    
    return $stats
}

# Internal function to generate actionable recommendations
function _generateRecommendations {
    [CmdletBinding()]
    param (
        [hashtable] $CoverageInfo
    )
    
    $recommendations = @()
    
    $lineCoverage = $CoverageInfo.LineRate * 100
    $branchCoverage = if ($CoverageInfo.BranchesValid -gt 0) { $CoverageInfo.BranchRate * 100 } else { 0 }
    
    # Line coverage recommendations
    if ($lineCoverage -lt 70) {
        $recommendations += "🎯 **Priority**: Increase line coverage to at least 70% by focusing on the most critical and frequently used code paths."
    } elseif ($lineCoverage -lt 80) {
        $recommendations += "📈 **Target**: Aim for 80% line coverage by adding tests for remaining uncovered lines."
    } elseif ($lineCoverage -lt 90) {
        $recommendations += "🏆 **Excellence**: Push towards 90% coverage for production-critical components."
    }
    
    # Branch coverage recommendations
    if ($CoverageInfo.BranchesValid -gt 0) {
        $branchGap = $lineCoverage - $branchCoverage
        if ($branchGap -gt 15) {
            $recommendations += "🔀 **Branch Testing**: Significant branch coverage gap detected. Focus on testing conditional logic, loops, and error handling paths."
        } elseif ($branchCoverage -lt 70) {
            $recommendations += "🔄 **Conditional Logic**: Improve branch coverage by testing all code paths in conditional statements."
        }
    }
    
    # Complexity recommendations
    if ($CoverageInfo.Complexity -gt 10) {
        $recommendations += "⚙️ **Complexity**: High code complexity detected. Consider refactoring complex methods to improve testability."
    }
    
    # General recommendations
    if ($recommendations.Count -eq 0 -and $lineCoverage -ge 90) {
        $recommendations += "✨ **Maintenance**: Excellent coverage! Focus on maintaining this level as the codebase evolves."
    }
    
    return $recommendations
}

# Internal function to assess code complexity
function _getComplexityAssessment {
    [CmdletBinding()]
    param (
        [double] $Complexity
    )
    
    if ($Complexity -le 5) {
        return "Low complexity - easy to test and maintain"
    } elseif ($Complexity -le 10) {
        return "Moderate complexity - manageable with good practices"
    } elseif ($Complexity -le 20) {
        return "High complexity - consider refactoring"
    } else {
        return "Very high complexity - refactoring recommended"
    }
}

<#
.SYNOPSIS
    Creates a coverage trend summary when comparing multiple reports.
.DESCRIPTION
    Generates a summary comparing current coverage metrics with previous reports
    to show trends and progress over time.
.PARAMETER CurrentCoverage
    The current coverage information.
.PARAMETER PreviousCoverage
    The previous coverage information for comparison.
.OUTPUTS
    Returns an array of strings representing the trend summary.
#>
function New-CoverageTrendSummary
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] $CurrentCoverage,
        
        [Parameter(Mandatory=$true)]
        [hashtable] $PreviousCoverage
    )
    
    $summary = @()
    
    # Calculate changes
    $lineCoverageChange = ($CurrentCoverage.LineRate - $PreviousCoverage.LineRate) * 100
    $branchCoverageChange = ($CurrentCoverage.BranchRate - $PreviousCoverage.BranchRate) * 100
    
    $summary += "### Coverage Trends"
    $summary += ""
    
    # Line coverage trend
    if ($lineCoverageChange -gt 1) {
        $summary += "📈 **Line Coverage Improved** by $($lineCoverageChange.ToString('F1'))% percentage points"
    } elseif ($lineCoverageChange -lt -1) {
        $summary += "📉 **Line Coverage Declined** by $([Math]::Abs($lineCoverageChange).ToString('F1'))% percentage points"
    } else {
        $summary += "➡️ **Line Coverage Stable** (change: $($lineCoverageChange.ToString('F1'))%)"
    }
    
    # Branch coverage trend  
    if ($CurrentCoverage.BranchesValid -gt 0 -and $PreviousCoverage.BranchesValid -gt 0) {
        if ($branchCoverageChange -gt 1) {
            $summary += "📈 **Branch Coverage Improved** by $($branchCoverageChange.ToString('F1'))% percentage points"
        } elseif ($branchCoverageChange -lt -1) {
            $summary += "📉 **Branch Coverage Declined** by $([Math]::Abs($branchCoverageChange).ToString('F1'))% percentage points"
        } else {
            $summary += "➡️ **Branch Coverage Stable** (change: $($branchCoverageChange.ToString('F1'))%)"
        }
    }
    
    return $summary
}