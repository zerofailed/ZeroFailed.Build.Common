# <copyright file="New-CoverageSummary.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    . $PSCommandPath.Replace('New-CoverageSummary.Tests.ps1','Format-CoveragePercentage.ps1')
}

Describe 'New-CoverageSummary' {
    
    BeforeAll {
        $script:excellentCoverage = @{
            LineRate = 0.925
            BranchRate = 0.885
            Complexity = 3.2
            LinesValid = 1000
            LinesCovered = 925
            BranchesValid = 200
            BranchesCovered = 177
        }
        
        $script:moderateCoverage = @{
            LineRate = 0.755
            BranchRate = 0.685
            Complexity = 6.8
            LinesValid = 1500
            LinesCovered = 1133
            BranchesValid = 300
            BranchesCovered = 206
        }
        
        $script:poorCoverage = @{
            LineRate = 0.425
            BranchRate = 0.285
            Complexity = 12.5
            LinesValid = 800
            LinesCovered = 340
            BranchesValid = 150
            BranchesCovered = 43
        }
    }

    Context 'Excellent coverage summary' {
        It 'should generate positive assessment for excellent coverage' {
            $result = New-CoverageSummary -CoverageInfo $script:excellentCoverage -PackageCount 15 -Style Simple
            
            $result -join " " | Should -Match "Excellent Coverage"
            $result | Should -Contain "📊 **Overall Line Coverage:** 92.5% (925 of 1000 lines covered)"
            $result | Should -Contain "📈 **Branch Coverage:** 88.5% (177 of 200 branches covered)"
            $result | Should -Contain "📦 **Packages Analyzed:** 15"
            $result | Should -Contain "🔧 **Code Complexity:** 3.2 (Low complexity - easy to test and maintain)"
        }

        It 'should include quick stats for excellent coverage' {
            $result = New-CoverageSummary -CoverageInfo $script:excellentCoverage -PackageCount 15
            
            $result | Should -Contain "### Quick Stats"
            $result | Should -Contain "- **Lines of Code:** 1,000"
            $result | Should -Contain "- **Covered Lines:** 925"
            $result | Should -Contain "- **Uncovered Lines:** 75"
            $result | Should -Contain "- **Total Branches:** 200"
            $result | Should -Contain "- **Covered Branches:** 177"
            $result | Should -Contain "- **Packages:** 15"
            $result | Should -Contain "- **Average Complexity:** 3.2"
        }
    }

    Context 'Moderate coverage summary' {
        It 'should generate moderate assessment for moderate coverage' {
            $result = New-CoverageSummary -CoverageInfo $script:moderateCoverage -PackageCount 8
            
            $result -join " " | Should -Match "Moderate Coverage"
            $result | Should -Contain "📊 **Overall Line Coverage:** ✔️ 75.5% (1133 of 1500 lines covered)"
        }

        It 'should detect branch coverage gap' {
            $result = New-CoverageSummary -CoverageInfo $script:moderateCoverage -PackageCount 8
            
            # Line coverage 75.5% - Branch coverage 68.5% = 7% gap (should be noted)
            $result -join " " | Should -Match "Branch coverage lags behind line coverage"
        }
    }

    Context 'Poor coverage summary' {
        It 'should generate critical assessment for poor coverage' {
            $result = New-CoverageSummary -CoverageInfo $script:poorCoverage -PackageCount 5
            
            $result -join " " | Should -Match "Low Coverage|Critical Coverage Gap"
            $result | Should -Contain "📊 **Overall Line Coverage:** ❌ 42.5% (340 of 800 lines covered)"
        }

        It 'should highlight high complexity issues' {
            $result = New-CoverageSummary -CoverageInfo $script:poorCoverage -PackageCount 5
            
            $result | Should -Contain "🔧 **Code Complexity:** 🔴 12.5 (High complexity - consider refactoring)"
        }
    }

    Context 'Coverage with recommendations' {
        It 'should include recommendations when requested' {
            $result = New-CoverageSummary -CoverageInfo $script:moderateCoverage -PackageCount 8 -IncludeRecommendations
            
            $result | Should -Contain "### Key Recommendations"
            $result -join " " | Should -Match "Target.*80%|Priority.*70%"
        }

        It 'should provide maintenance recommendation for excellent coverage' {
            $result = New-CoverageSummary -CoverageInfo $script:excellentCoverage -PackageCount 15 -IncludeRecommendations
            
            $result | Should -Contain "### Key Recommendations"
            $result -join " " | Should -Match "Maintenance.*Excellent coverage"
        }

        It 'should provide branch coverage recommendations for large gap' {
            $largeBranchGap = @{
                LineRate = 0.85
                BranchRate = 0.65  # 20% gap
                Complexity = 5.0
                LinesValid = 1000
                LinesCovered = 850
                BranchesValid = 200
                BranchesCovered = 130
            }
            
            $result = New-CoverageSummary -CoverageInfo $largeBranchGap -PackageCount 10 -IncludeRecommendations
            
            $result -join " " | Should -Match "Branch Testing.*gap detected"
        }
    }

    Context 'Edge cases' {
        It 'should handle zero branches gracefully' {
            $noBranches = @{
                LineRate = 0.85
                BranchRate = 0
                Complexity = 2.0
                LinesValid = 500
                LinesCovered = 425
                BranchesValid = 0
                BranchesCovered = 0
            }
            
            $result = New-CoverageSummary -CoverageInfo $noBranches -PackageCount 5
            
            $result | Should -Not -Match "Branch Coverage"
            $result | Should -Contain "📊 **Overall Line Coverage:** ✔️ 85.0% (425 of 500 lines covered)"
        }

        It 'should handle zero complexity gracefully' {
            $noComplexity = @{
                LineRate = 0.85
                BranchRate = 0.75
                Complexity = 0
                LinesValid = 500
                LinesCovered = 425
                BranchesValid = 100
                BranchesCovered = 75
            }
            
            $result = New-CoverageSummary -CoverageInfo $noComplexity -PackageCount 5
            
            $result | Should -Not -Match "Code Complexity"
            $result | Should -Not -Match "Average Complexity"
        }

        It 'should handle zero packages' {
            $result = New-CoverageSummary -CoverageInfo $script:excellentCoverage -PackageCount 0
            
            $result | Should -Contain "📦 **Packages Analyzed:** 0"
        }
    }

    Context 'Different formatting styles' {
        It 'should use icons when style is Icon' {
            $result = New-CoverageSummary -CoverageInfo $script:excellentCoverage -PackageCount 15 -Style Icon
            
            $result | Should -Contain "📊 **Overall Line Coverage:** ✅ 92.5%"
        }

        It 'should use progress bars when style is ProgressBar' {
            $result = New-CoverageSummary -CoverageInfo $script:excellentCoverage -PackageCount 15 -Style ProgressBar
            
            $result -join " " | Should -Match "█{9}░.*92\.5%"
        }
    }
}

Describe 'New-CoverageTrendSummary' {
    
    BeforeAll {
        $script:currentCoverage = @{
            LineRate = 0.85
            BranchRate = 0.78
            BranchesValid = 200
        }
        
        $script:previousHigherCoverage = @{
            LineRate = 0.92
            BranchRate = 0.85
            BranchesValid = 200
        }
        
        $script:previousLowerCoverage = @{
            LineRate = 0.75
            BranchRate = 0.68
            BranchesValid = 200
        }
        
        $script:previousSimilarCoverage = @{
            LineRate = 0.84
            BranchRate = 0.77
            BranchesValid = 200
        }
    }

    Context 'Coverage improvements' {
        It 'should detect line coverage improvement' {
            $result = New-CoverageTrendSummary -CurrentCoverage $script:currentCoverage -PreviousCoverage $script:previousLowerCoverage
            
            $result | Should -Contain "### Coverage Trends"
            $result -join " " | Should -Match "Line Coverage Improved.*10\.0%"
        }

        It 'should detect branch coverage improvement' {
            $result = New-CoverageTrendSummary -CurrentCoverage $script:currentCoverage -PreviousCoverage $script:previousLowerCoverage
            
            $result -join " " | Should -Match "Branch Coverage Improved.*10\.0%"
        }
    }

    Context 'Coverage declines' {
        It 'should detect line coverage decline' {
            $result = New-CoverageTrendSummary -CurrentCoverage $script:currentCoverage -PreviousCoverage $script:previousHigherCoverage
            
            $result -join " " | Should -Match "Line Coverage Declined.*7\.0%"
        }

        It 'should detect branch coverage decline' {
            $result = New-CoverageTrendSummary -CurrentCoverage $script:currentCoverage -PreviousCoverage $script:previousHigherCoverage
            
            $result -join " " | Should -Match "Branch Coverage Declined.*7\.0%"
        }
    }

    Context 'Stable coverage' {
        It 'should detect stable coverage' {
            $result = New-CoverageTrendSummary -CurrentCoverage $script:currentCoverage -PreviousCoverage $script:previousSimilarCoverage
            
            $result -join " " | Should -Match "Line Coverage Stable.*1\.0%"
            $result -join " " | Should -Match "Branch Coverage Stable.*1\.0%"
        }
    }

    Context 'Edge cases' {
        It 'should handle missing branch data' {
            $noBranchCurrent = @{ LineRate = 0.85; BranchRate = 0; BranchesValid = 0 }
            $noBranchPrevious = @{ LineRate = 0.75; BranchRate = 0; BranchesValid = 0 }
            
            $result = New-CoverageTrendSummary -CurrentCoverage $noBranchCurrent -PreviousCoverage $noBranchPrevious
            
            $result | Should -Not -Match "Branch Coverage"
            $result -join " " | Should -Match "Line Coverage.*10\.0%"
        }
    }
}