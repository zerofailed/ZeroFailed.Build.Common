# <copyright file="Format-CoveragePercentage.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
    Formats coverage percentages with visual indicators and badges for Markdown reports.
.DESCRIPTION
    This function takes a coverage percentage value and formats it with appropriate visual
    indicators, colors, and badges to enhance the readability of coverage reports in Markdown.
    It provides different formatting options including text icons, badges, and progress bars.
.EXAMPLE
    PS C:\> Format-CoveragePercentage -Percentage 85.5
    ✅ 85.5%
    
    Formats a coverage percentage with a success icon.
.EXAMPLE
    PS C:\> Format-CoveragePercentage -Percentage 45.2 -Style Badge
    ![Coverage](https://img.shields.io/badge/coverage-45.2%25-red)
    
    Creates a red badge for low coverage.
.EXAMPLE
    PS C:\> Format-CoveragePercentage -Percentage 78.9 -MinimumThreshold 80 -Style ProgressBar
    ⚠️ 78.9% ████████░░ (78.9%)
    
    Creates a progress bar with warning icon for below-threshold coverage.
.PARAMETER Percentage
    The coverage percentage value (0-100).
.PARAMETER MinimumThreshold
    The minimum coverage threshold for determining color/icon (default: 70).
.PARAMETER GoodThreshold
    The threshold for "good" coverage (default: 90).
.PARAMETER Style
    The formatting style to use: Icon, Badge, ProgressBar, or Simple.
.PARAMETER DecimalPlaces
    Number of decimal places to display (default: 1).
.OUTPUTS
    Returns a formatted string with the coverage percentage and visual indicators.
#>
function Format-CoveragePercentage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [double] $Percentage,
        
        [Parameter()]
        [double] $MinimumThreshold = 70.0,
        
        [Parameter()]
        [double] $GoodThreshold = 90.0,
        
        [Parameter()]
        [ValidateSet('Icon', 'Badge', 'ProgressBar', 'Simple')]
        [string] $Style = 'Icon',
        
        [Parameter()]
        [int] $DecimalPlaces = 1
    )

    # Ensure percentage is within valid range
    $Percentage = [Math]::Max(0.0, [Math]::Min(100.0, $Percentage))
    
    # Format the percentage value
    $formattedPercentage = $Percentage.ToString("F$DecimalPlaces")
    
    switch ($Style) {
        'Icon' {
            return _formatWithIcon -Percentage $Percentage -FormattedPercentage $formattedPercentage -MinimumThreshold $MinimumThreshold -GoodThreshold $GoodThreshold
        }
        'Badge' {
            return _formatWithBadge -Percentage $Percentage -FormattedPercentage $formattedPercentage -MinimumThreshold $MinimumThreshold -GoodThreshold $GoodThreshold
        }
        'ProgressBar' {
            return _formatWithProgressBar -Percentage $Percentage -FormattedPercentage $formattedPercentage -MinimumThreshold $MinimumThreshold -GoodThreshold $GoodThreshold
        }
        'Simple' {
            return "$formattedPercentage%"
        }
    }
}

# Internal function to format with text icons
function _formatWithIcon {
    [CmdletBinding()]
    param (
        [double] $Percentage,
        [string] $FormattedPercentage,
        [double] $MinimumThreshold,
        [double] $GoodThreshold
    )
    
    if ($Percentage -ge $GoodThreshold) {
        return "✅ $FormattedPercentage%"
    } elseif ($Percentage -ge $MinimumThreshold) {
        return "✔️ $FormattedPercentage%"
    } elseif ($Percentage -ge ($MinimumThreshold * 0.5)) {
        return "⚠️ $FormattedPercentage%"
    } else {
        return "❌ $FormattedPercentage%"
    }
}

# Internal function to format with shields.io badges
function _formatWithBadge {
    [CmdletBinding()]
    param (
        [double] $Percentage,
        [string] $FormattedPercentage,
        [double] $MinimumThreshold,
        [double] $GoodThreshold
    )
    
    # URL encode the percentage for badge
    $encodedPercentage = [uri]::EscapeDataString("$FormattedPercentage%")
    
    # Determine badge color
    $color = if ($Percentage -ge $GoodThreshold) {
        'brightgreen'
    } elseif ($Percentage -ge $MinimumThreshold) {
        'green'
    } elseif ($Percentage -ge ($MinimumThreshold * 0.7)) {
        'yellow'
    } elseif ($Percentage -ge ($MinimumThreshold * 0.5)) {
        'orange'
    } else {
        'red'
    }
    
    return "![Coverage](https://img.shields.io/badge/coverage-$encodedPercentage-$color)"
}

# Internal function to format with ASCII progress bar
function _formatWithProgressBar {
    [CmdletBinding()]
    param (
        [double] $Percentage,
        [string] $FormattedPercentage,
        [double] $MinimumThreshold,
        [double] $GoodThreshold
    )
    
    # Create progress bar (10 characters total)
    $filledBlocks = [Math]::Floor($Percentage / 10)
    $emptyBlocks = 10 - $filledBlocks
    
    $progressBar = ('█' * $filledBlocks) + ('░' * $emptyBlocks)
    
    # Add appropriate icon
    $icon = if ($Percentage -ge $GoodThreshold) {
        "✅"
    } elseif ($Percentage -ge $MinimumThreshold) {
        "✔️"
    } elseif ($Percentage -ge ($MinimumThreshold * 0.5)) {
        "⚠️"
    } else {
        "❌"
    }
    
    return "$icon $FormattedPercentage% $progressBar"
}

<#
.SYNOPSIS
    Formats multiple coverage metrics into a consistent visual format.
.DESCRIPTION
    This function formats line coverage, branch coverage, and complexity metrics
    in a consistent way for display in tables and reports.
.PARAMETER LineCoverage
    The line coverage percentage.
.PARAMETER BranchCoverage
    The branch coverage percentage (optional).
.PARAMETER Complexity
    The code complexity metric (optional).
.PARAMETER Style
    The formatting style to use.
.PARAMETER MinimumThreshold
    The minimum coverage threshold.
.OUTPUTS
    Returns a hashtable with formatted coverage metrics.
#>
function Format-CoverageMetrics
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [double] $LineCoverage,
        
        [Parameter()]
        [double] $BranchCoverage = -1,
        
        [Parameter()]
        [double] $Complexity = -1,
        
        [Parameter()]
        [ValidateSet('Icon', 'Badge', 'ProgressBar', 'Simple')]
        [string] $Style = 'Icon',
        
        [Parameter()]
        [double] $MinimumThreshold = 70.0
    )
    
    $result = @{
        Line = Format-CoveragePercentage -Percentage ($LineCoverage * 100) -Style $Style -MinimumThreshold $MinimumThreshold
    }
    
    if ($BranchCoverage -ge 0) {
        $result.Branch = Format-CoveragePercentage -Percentage ($BranchCoverage * 100) -Style $Style -MinimumThreshold $MinimumThreshold
    }
    
    if ($Complexity -ge 0) {
        $result.Complexity = $Complexity.ToString('F1')
        
        # Add complexity indicator
        if ($Style -eq 'Icon') {
            if ($Complexity -le 5) {
                $result.Complexity = "🟢 $($result.Complexity)"
            } elseif ($Complexity -le 10) {
                $result.Complexity = "🟡 $($result.Complexity)"
            } else {
                $result.Complexity = "🔴 $($result.Complexity)"
            }
        }
    }
    
    return $result
}