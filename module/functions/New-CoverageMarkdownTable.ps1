# <copyright file="New-CoverageMarkdownTable.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
    Generates formatted Markdown tables for code coverage data at different aggregation levels.
.DESCRIPTION
    This function creates well-formatted Markdown tables for displaying coverage metrics
    at various levels (Overall, Package, Class, Method). It supports sorting, filtering,
    and visual formatting to enhance the readability of coverage reports.
.EXAMPLE
    PS C:\> New-CoverageMarkdownTable -Data $packages -Type Package -MinimumCoverage 70
    
    | Package | Line Coverage | Branch Coverage | Classes | Lines | Complexity |
    |---------|---------------|-----------------|---------|-------|------------|
    | com.example.core | ✔️ 85.5% | ✔️ 78.2% | 15 | 1,250 | 🟢 4.2 |
    | com.example.util | ⚠️ 65.3% | ⚠️ 58.1% | 8 | 750 | 🟡 6.8 |
.EXAMPLE
    PS C:\> New-CoverageMarkdownTable -Data $methods -Type Method -SortBy LineRate -Ascending:$false -Top 10
    
    Generates a table of the top 10 methods sorted by line coverage rate.
.PARAMETER Data
    Array of coverage data objects to include in the table.
.PARAMETER Type
    The type of coverage data: Overall, Package, Class, or Method.
.PARAMETER MinimumCoverage
    The minimum coverage threshold for highlighting low coverage items.
.PARAMETER SortBy
    Field to sort by: Name, LineRate, BranchRate, or Complexity.
.PARAMETER Ascending
    Sort in ascending order (default: true for Name, false for coverage metrics).
.PARAMETER Top
    Limit the table to the top N items after sorting.
.PARAMETER IncludeComplexity
    Include complexity metrics in the table (default: true).
.PARAMETER Style
    Formatting style for percentages: Icon, Badge, ProgressBar, or Simple.
.OUTPUTS
    Returns an array of strings representing the Markdown table.
#>
function New-CoverageMarkdownTable
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array] $Data,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Overall', 'Package', 'Class', 'Method')]
        [string] $Type,
        
        [Parameter()]
        [double] $MinimumCoverage = 70.0,
        
        [Parameter()]
        [ValidateSet('Name', 'LineRate', 'BranchRate', 'Complexity')]
        [string] $SortBy = 'Name',
        
        [Parameter()]
        [bool] $Ascending = $true,
        
        [Parameter()]
        [int] $Top = 0,
        
        [Parameter()]
        [bool] $IncludeComplexity = $true,
        
        [Parameter()]
        [ValidateSet('Icon', 'Badge', 'ProgressBar', 'Simple')]
        [string] $Style = 'Icon'
    )

    if (-not $Data -or $Data.Count -eq 0) {
        return @("*No data available*")
    }

    # Sort the data
    $sortedData = _sortCoverageData -Data $Data -SortBy $SortBy -Ascending $Ascending
    
    # Limit to top N if specified
    if ($Top -gt 0) {
        $sortedData = $sortedData | Select-Object -First $Top
    }

    # Generate table based on type
    switch ($Type) {
        'Overall' { return _generateOverallTable -Data $sortedData -MinimumCoverage $MinimumCoverage -Style $Style -IncludeComplexity $IncludeComplexity }
        'Package' { return _generatePackageTable -Data $sortedData -MinimumCoverage $MinimumCoverage -Style $Style -IncludeComplexity $IncludeComplexity }
        'Class' { return _generateClassTable -Data $sortedData -MinimumCoverage $MinimumCoverage -Style $Style -IncludeComplexity $IncludeComplexity }
        'Method' { return _generateMethodTable -Data $sortedData -MinimumCoverage $MinimumCoverage -Style $Style -IncludeComplexity $IncludeComplexity }
    }
}

# Internal function to sort coverage data
function _sortCoverageData {
    [CmdletBinding()]
    param (
        [array] $Data,
        [string] $SortBy,
        [bool] $Ascending
    )
    
    switch ($SortBy) {
        'LineRate' {
            if ($Ascending) {
                return $Data | Sort-Object LineRate
            } else {
                return $Data | Sort-Object LineRate -Descending
            }
        }
        'BranchRate' {
            if ($Ascending) {
                return $Data | Sort-Object BranchRate
            } else {
                return $Data | Sort-Object BranchRate -Descending
            }
        }
        'Complexity' {
            if ($Ascending) {
                return $Data | Sort-Object Complexity
            } else {
                return $Data | Sort-Object Complexity -Descending
            }
        }
        default { # Name
            if ($Ascending) {
                return $Data | Sort-Object Name
            } else {
                return $Data | Sort-Object Name -Descending
            }
        }
    }
}

# Internal function to generate overall coverage table
function _generateOverallTable {
    [CmdletBinding()]
    param (
        [array] $Data,
        [double] $MinimumCoverage,
        [string] $Style,
        [bool] $IncludeComplexity
    )
    
    $table = @()
    
    # Header
    if ($IncludeComplexity) {
        $table += "| Metric | Value | Lines | Branches | Complexity |"
        $table += "|--------|-------|-------|----------|------------|"
    } else {
        $table += "| Metric | Value | Lines | Branches |"
        $table += "|--------|-------|-------|----------|"
    }
    
    # Data rows
    foreach ($item in $Data) {
        $lineMetrics = Format-CoverageMetrics -LineCoverage $item.LineRate -BranchCoverage $item.BranchRate -Complexity $item.Complexity -Style $Style -MinimumThreshold $MinimumCoverage
        
        $linesInfo = "$($item.LinesCovered) / $($item.LinesValid)"
        $branchesInfo = "$($item.BranchesCovered) / $($item.BranchesValid)"
        
        if ($IncludeComplexity) {
            $table += "| Overall Coverage | $($lineMetrics.Line) | $linesInfo | $branchesInfo | $($lineMetrics.Complexity) |"
        } else {
            $table += "| Overall Coverage | $($lineMetrics.Line) | $linesInfo | $branchesInfo |"
        }
    }
    
    return $table
}

# Internal function to generate package-level table
function _generatePackageTable {
    [CmdletBinding()]
    param (
        [array] $Data,
        [double] $MinimumCoverage,
        [string] $Style,
        [bool] $IncludeComplexity
    )
    
    $table = @()
    
    # Header
    if ($IncludeComplexity) {
        $table += "| Package | Line Coverage | Branch Coverage | Classes | Complexity |"
        $table += "|---------|---------------|-----------------|---------|------------|"
    } else {
        $table += "| Package | Line Coverage | Branch Coverage | Classes |"
        $table += "|---------|---------------|-----------------|---------|"
    }
    
    # Data rows
    foreach ($package in $Data) {
        $metrics = Format-CoverageMetrics -LineCoverage $package.LineRate -BranchCoverage $package.BranchRate -Complexity $package.Complexity -Style $Style -MinimumThreshold $MinimumCoverage
        
        $packageName = if ($package.Name) { $package.Name } else { "*root*" }
        $classCount = if ($package.Classes) { $package.Classes.Count } else { 0 }
        
        if ($IncludeComplexity) {
            $table += "| $packageName | $($metrics.Line) | $($metrics.Branch) | $classCount | $($metrics.Complexity) |"
        } else {
            $table += "| $packageName | $($metrics.Line) | $($metrics.Branch) | $classCount |"
        }
    }
    
    return $table
}

# Internal function to generate class-level table
function _generateClassTable {
    [CmdletBinding()]
    param (
        [array] $Data,
        [double] $MinimumCoverage,
        [string] $Style,
        [bool] $IncludeComplexity
    )
    
    $table = @()
    
    # Header
    if ($IncludeComplexity) {
        $table += "| Class | Line Coverage | Branch Coverage | Methods | Complexity |"
        $table += "|-------|---------------|-----------------|---------|------------|"
    } else {
        $table += "| Class | Line Coverage | Branch Coverage | Methods |"
        $table += "|-------|---------------|-----------------|---------|"
    }
    
    # Data rows
    foreach ($class in $Data) {
        $metrics = Format-CoverageMetrics -LineCoverage $class.LineRate -BranchCoverage $class.BranchRate -Complexity $class.Complexity -Style $Style -MinimumThreshold $MinimumCoverage
        
        $className = if ($class.Name) { '`' + $class.Name + '`' } else { "*unknown*" }
        $methodCount = if ($class.Methods) { $class.Methods.Count } else { 0 }
        
        if ($IncludeComplexity) {
            $table += "| $className | $($metrics.Line) | $($metrics.Branch) | $methodCount | $($metrics.Complexity) |"
        } else {
            $table += "| $className | $($metrics.Line) | $($metrics.Branch) | $methodCount |"
        }
    }
    
    return $table
}

# Internal function to generate method-level table
function _generateMethodTable {
    [CmdletBinding()]
    param (
        [array] $Data,
        [double] $MinimumCoverage,
        [string] $Style,
        [bool] $IncludeComplexity
    )
    
    $table = @()
    
    # Header
    if ($IncludeComplexity) {
        $table += "| Method | Line Coverage | Branch Coverage | Lines | Complexity |"
        $table += "|--------|---------------|-----------------|-------|------------|"
    } else {
        $table += "| Method | Line Coverage | Branch Coverage | Lines |"
        $table += "|--------|---------------|-----------------|-------|"
    }
    
    # Data rows
    foreach ($method in $Data) {
        $metrics = Format-CoverageMetrics -LineCoverage $method.LineRate -BranchCoverage $method.BranchRate -Complexity $method.Complexity -Style $Style -MinimumThreshold $MinimumCoverage
        
        $methodName = if ($method.Name) { '`' + $method.Name + '`' } else { "*unknown*" }
        $lineCount = if ($method.Lines) { $method.Lines.Count } else { 0 }
        
        if ($IncludeComplexity) {
            $table += "| $methodName | $($metrics.Line) | $($metrics.Branch) | $lineCount | $($metrics.Complexity) |"
        } else {
            $table += "| $methodName | $($metrics.Line) | $($metrics.Branch) | $lineCount |"
        }
    }
    
    return $table
}

<#
.SYNOPSIS
    Creates a summary statistics table for coverage data.
.DESCRIPTION
    Generates a summary table with key statistics about the coverage data,
    including totals, averages, and distribution information.
.PARAMETER Data
    The coverage data to analyze.
.PARAMETER Type
    The type of data being summarized.
.OUTPUTS
    Returns an array of strings representing the summary table.
#>
function New-CoverageSummaryTable
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array] $Data,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Package', 'Class', 'Method')]
        [string] $Type
    )

    if (-not $Data -or $Data.Count -eq 0) {
        return @("*No data available*")
    }

    $table = @()
    $table += "| Statistic | Value |"
    $table += "|-----------|-------|"
    
    # Count
    $table += "| Total $($Type)s | $($Data.Count) |"
    
    # Coverage statistics
    $lineCoverages = $Data | ForEach-Object { $_.LineRate * 100 }
    $avgLineCoverage = ($lineCoverages | Measure-Object -Average).Average
    $minLineCoverage = ($lineCoverages | Measure-Object -Minimum).Minimum
    $maxLineCoverage = ($lineCoverages | Measure-Object -Maximum).Maximum
    
    $table += "| Average Line Coverage | $($avgLineCoverage.ToString('F1'))% |"
    $table += "| Minimum Line Coverage | $($minLineCoverage.ToString('F1'))% |"
    $table += "| Maximum Line Coverage | $($maxLineCoverage.ToString('F1'))% |"
    
    # Distribution
    $excellentCount = @($Data | Where-Object { $_.LineRate -ge 0.9 }).Count
    $goodCount = @($Data | Where-Object { $_.LineRate -ge 0.7 -and $_.LineRate -lt 0.9 }).Count
    $poorCount = @($Data | Where-Object { $_.LineRate -lt 0.7 }).Count
    
    $table += "| Excellent Coverage (≥90%) | $excellentCount |"
    $table += "| Good Coverage (70-89%) | $goodCount |"
    $table += "| Poor Coverage (<70%) | $poorCount |"
    
    return $table
}