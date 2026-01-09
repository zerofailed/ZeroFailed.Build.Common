# <copyright file="Format-CoveragePercentage.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe 'Format-CoveragePercentage' {
    
    Context 'Icon style formatting' {
        It 'should show green check for excellent coverage (≥90%)' {
            $result = Format-CoveragePercentage -Percentage 95.5 -Style Icon
            $result | Should -Be "✅ 95.5%"
        }

        It 'should show check mark for good coverage (≥70%, <90%)' {
            $result = Format-CoveragePercentage -Percentage 85.2 -Style Icon
            $result | Should -Be "✔️ 85.2%"
        }

        It 'should show warning for moderate coverage (≥35%, <70%)' {
            $result = Format-CoveragePercentage -Percentage 55.8 -Style Icon
            $result | Should -Be "⚠️ 55.8%"
        }

        It 'should show X for poor coverage (<35%)' {
            $result = Format-CoveragePercentage -Percentage 25.3 -Style Icon
            $result | Should -Be "❌ 25.3%"
        }

        It 'should respect custom thresholds' {
            $result = Format-CoveragePercentage -Percentage 75.0 -Style Icon -MinimumThreshold 80 -GoodThreshold 95
            $result | Should -Be "⚠️ 75.0%"
        }
    }

    Context 'Badge style formatting' {
        It 'should create green badge for excellent coverage' {
            $result = Format-CoveragePercentage -Percentage 95.5 -Style Badge
            $result | Should -Be "![Coverage](https://img.shields.io/badge/coverage-95.5%25-brightgreen)"
        }

        It 'should create red badge for poor coverage' {
            $result = Format-CoveragePercentage -Percentage 25.3 -Style Badge
            $result | Should -Be "![Coverage](https://img.shields.io/badge/coverage-25.3%25-red)"
        }

        It 'should create yellow badge for moderate coverage' {
            $result = Format-CoveragePercentage -Percentage 55.0 -Style Badge -MinimumThreshold 70
            $result | Should -Be "![Coverage](https://img.shields.io/badge/coverage-55.0%25-yellow)"
        }
    }

    Context 'Progress bar style formatting' {
        It 'should create progress bar for high coverage' {
            $result = Format-CoveragePercentage -Percentage 90.0 -Style ProgressBar
            $result | Should -Be "✅ 90.0% █████████░"
        }

        It 'should create progress bar for moderate coverage' {
            $result = Format-CoveragePercentage -Percentage 50.0 -Style ProgressBar
            $result | Should -Be "⚠️ 50.0% █████░░░░░"
        }

        It 'should create progress bar for poor coverage' {
            $result = Format-CoveragePercentage -Percentage 20.0 -Style ProgressBar
            $result | Should -Be "❌ 20.0% ██░░░░░░░░"
        }

        It 'should handle 0% coverage' {
            $result = Format-CoveragePercentage -Percentage 0.0 -Style ProgressBar
            $result | Should -Be "❌ 0.0% ░░░░░░░░░░"
        }

        It 'should handle 100% coverage' {
            $result = Format-CoveragePercentage -Percentage 100.0 -Style ProgressBar
            $result | Should -Be "✅ 100.0% ██████████"
        }
    }

    Context 'Simple style formatting' {
        It 'should return just the percentage' {
            $result = Format-CoveragePercentage -Percentage 85.5 -Style Simple
            $result | Should -Be "85.5%"
        }
    }

    Context 'Decimal places formatting' {
        It 'should format with custom decimal places' {
            $result = Format-CoveragePercentage -Percentage 85.567 -Style Simple -DecimalPlaces 2
            $result | Should -Be "85.57%"
        }

        It 'should format with zero decimal places' {
            $result = Format-CoveragePercentage -Percentage 85.567 -Style Simple -DecimalPlaces 0
            $result | Should -Be "86%"
        }
    }

    Context 'Edge cases' {
        It 'should handle percentage above 100' {
            $result = Format-CoveragePercentage -Percentage 150.0 -Style Simple
            $result | Should -Be "100.0%"
        }

        It 'should handle negative percentage' {
            $result = Format-CoveragePercentage -Percentage -25.0 -Style Simple
            $result | Should -Be "0.0%"
        }
    }
}

Describe 'Format-CoverageMetrics' {
    
    Context 'Line coverage only' {
        It 'should format line coverage only' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -Style Simple
            
            $result.Line | Should -Be "85.0%"
            $result.Branch | Should -BeNullOrEmpty
            $result.Complexity | Should -BeNullOrEmpty
        }
    }

    Context 'Full metrics with icons' {
        It 'should format all metrics with icons' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -BranchCoverage 0.75 -Complexity 3.5 -Style Icon
            
            $result.Line | Should -Be "✔️ 85.0%"
            $result.Branch | Should -Be "✔️ 75.0%"
            $result.Complexity | Should -Be "🟢 3.5"
        }
    }

    Context 'Complexity indicators' {
        It 'should show green for low complexity' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -Complexity 3.0 -Style Icon
            $result.Complexity | Should -Be "🟢 3.0"
        }

        It 'should show yellow for moderate complexity' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -Complexity 7.5 -Style Icon
            $result.Complexity | Should -Be "🟡 7.5"
        }

        It 'should show red for high complexity' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -Complexity 15.0 -Style Icon
            $result.Complexity | Should -Be "🔴 15.0"
        }
    }

    Context 'Optional parameters' {
        It 'should handle missing branch coverage' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -Complexity 5.0 -Style Simple
            
            $result.Line | Should -Be "85.0%"
            $result.Branch | Should -BeNullOrEmpty
            $result.Complexity | Should -Be "5.0"
        }

        It 'should handle missing complexity' {
            $result = Format-CoverageMetrics -LineCoverage 0.85 -BranchCoverage 0.75 -Style Simple
            
            $result.Line | Should -Be "85.0%"
            $result.Branch | Should -Be "75.0%"
            $result.Complexity | Should -BeNullOrEmpty
        }
    }
}