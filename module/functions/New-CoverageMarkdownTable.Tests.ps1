# <copyright file="New-CoverageMarkdownTable.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    . $PSCommandPath.Replace('New-CoverageMarkdownTable.Tests.ps1','Format-CoveragePercentage.ps1')
}

Describe 'New-CoverageMarkdownTable' {
    
    BeforeAll {
        # Test data
        $script:testPackages = @(
            @{ Name = 'com.example.core'; LineRate = 0.85; BranchRate = 0.78; Complexity = 4.2; Classes = @(@{}, @{}, @{}) }
            @{ Name = 'com.example.util'; LineRate = 0.65; BranchRate = 0.58; Complexity = 6.8; Classes = @(@{}, @{}) }
            @{ Name = 'com.example.web'; LineRate = 0.92; BranchRate = 0.89; Complexity = 3.1; Classes = @(@{}) }
        )
        
        $script:testClasses = @(
            @{ Name = 'TestClass1.java'; LineRate = 0.95; BranchRate = 0.88; Complexity = 2.5; Methods = @(@{}, @{}) }
            @{ Name = 'TestClass2.java'; LineRate = 0.72; BranchRate = 0.65; Complexity = 5.8; Methods = @(@{}) }
        )
        
        $script:testMethods = @(
            @{ Name = 'testMethod1'; LineRate = 1.0; BranchRate = 1.0; Complexity = 1.2; Lines = @(@{}, @{}) }
            @{ Name = 'testMethod2'; LineRate = 0.60; BranchRate = 0.45; Complexity = 8.5; Lines = @(@{}) }
        )
        
        $script:testOverall = @(
            @{ LineRate = 0.82; BranchRate = 0.75; Complexity = 4.8; LinesValid = 1000; LinesCovered = 820; BranchesValid = 200; BranchesCovered = 150 }
        )
    }

    Context 'Package table generation' {
        It 'should generate package table with all columns' {
            $result = New-CoverageMarkdownTable -Data $script:testPackages -Type Package -Style Simple
            
            $result | Should -Contain "| Package | Line Coverage | Branch Coverage | Classes | Complexity |"
            $result | Should -Contain "|---------|---------------|-----------------|---------|------------|"
            $result | Should -Contain "| com.example.core | 85.0% | 78.0% | 3 | 4.2 |"
            $result | Should -Contain "| com.example.util | 65.0% | 58.0% | 2 | 6.8 |"
            $result | Should -Contain "| com.example.web | 92.0% | 89.0% | 1 | 3.1 |"
        }

        It 'should generate package table without complexity' {
            $result = New-CoverageMarkdownTable -Data $script:testPackages -Type Package -Style Simple -IncludeComplexity:$false
            
            $result | Should -Contain "| Package | Line Coverage | Branch Coverage | Classes |"
            $result | Should -Contain "|---------|---------------|-----------------|---------|"
            $result | Should -Contain "| com.example.core | 85.0% | 78.0% | 3 |"
        }

        It 'should sort packages by line rate descending' {
            $result = New-CoverageMarkdownTable -Data $script:testPackages -Type Package -Style Simple -SortBy LineRate -Ascending:$false
            
            # Web package (92%) should be first, util package (65%) should be last
            $webIndex = ($result | Select-String "com.example.web").LineNumber
            $utilIndex = ($result | Select-String "com.example.util").LineNumber
            $webIndex | Should -BeLessThan $utilIndex
        }
    }

    Context 'Class table generation' {
        It 'should generate class table with code formatting' {
            $result = New-CoverageMarkdownTable -Data $script:testClasses -Type Class -Style Simple
            
            $result | Should -Contain "| Class | Line Coverage | Branch Coverage | Methods | Complexity |"
            $result | Should -Contain "| `TestClass1.java` | 95.0% | 88.0% | 2 | 2.5 |"
            $result | Should -Contain "| `TestClass2.java` | 72.0% | 65.0% | 1 | 5.8 |"
        }
    }

    Context 'Method table generation' {
        It 'should generate method table' {
            $result = New-CoverageMarkdownTable -Data $script:testMethods -Type Method -Style Simple
            
            $result | Should -Contain "| Method | Line Coverage | Branch Coverage | Lines | Complexity |"
            $result | Should -Contain "| `testMethod1` | 100.0% | 100.0% | 2 | 1.2 |"
            $result | Should -Contain "| `testMethod2` | 60.0% | 45.0% | 1 | 8.5 |"
        }
    }

    Context 'Overall table generation' {
        It 'should generate overall coverage table' {
            $result = New-CoverageMarkdownTable -Data $script:testOverall -Type Overall -Style Simple
            
            $result | Should -Contain "| Metric | Value | Lines | Branches | Complexity |"
            $result | Should -Contain "| Overall Coverage | 82.0% | 820 / 1000 | 150 / 200 | 4.8 |"
        }
    }

    Context 'Icon style formatting' {
        It 'should include icons when using Icon style' {
            $result = New-CoverageMarkdownTable -Data $script:testPackages -Type Package -Style Icon -MinimumCoverage 70
            
            $result | Should -Match "✅.*92\.0%"  # Web package - excellent
            $result | Should -Match "✔️.*85\.0%"  # Core package - good
            $result | Should -Match "⚠️.*65\.0%"  # Util package - warning
        }
    }

    Context 'Sorting and filtering' {
        It 'should limit results with Top parameter' {
            $result = New-CoverageMarkdownTable -Data $script:testPackages -Type Package -Style Simple -Top 2
            
            # Should have header + separator + 2 data rows = 4 total
            ($result | Where-Object { $_ -match '\|.*\|' }).Count | Should -Be 4
        }

        It 'should sort by complexity ascending' {
            $result = New-CoverageMarkdownTable -Data $script:testPackages -Type Package -Style Simple -SortBy Complexity -Ascending:$true
            
            # Web package (3.1) should be first, util package (6.8) should be last
            $webIndex = ($result | Select-String "com.example.web").LineNumber
            $utilIndex = ($result | Select-String "com.example.util").LineNumber
            $webIndex | Should -BeLessThan $utilIndex
        }
    }

    Context 'Empty data handling' {
        It 'should handle empty data gracefully' {
            $result = New-CoverageMarkdownTable -Data @() -Type Package -Style Simple
            
            $result | Should -Be "*No data available*"
        }

        It 'should handle null data gracefully' {
            $result = New-CoverageMarkdownTable -Data $null -Type Package -Style Simple
            
            $result | Should -Be "*No data available*"
        }
    }

    Context 'Edge cases' {
        It 'should handle packages with empty names' {
            $testData = @(@{ Name = ''; LineRate = 0.85; BranchRate = 0.78; Complexity = 4.2; Classes = @() })
            $result = New-CoverageMarkdownTable -Data $testData -Type Package -Style Simple
            
            $result | Should -Contain "| *root* |"
        }

        It 'should handle missing properties gracefully' {
            $testData = @(@{ Name = 'test'; LineRate = 0.85 })
            $result = New-CoverageMarkdownTable -Data $testData -Type Package -Style Simple
            
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'New-CoverageSummaryTable' {
    
    BeforeAll {
        $script:testSummaryData = @(
            @{ LineRate = 0.95 }
            @{ LineRate = 0.85 }
            @{ LineRate = 0.75 }
            @{ LineRate = 0.65 }
            @{ LineRate = 0.55 }
        )
    }

    Context 'Summary statistics' {
        It 'should generate summary table with statistics' {
            $result = New-CoverageSummaryTable -Data $script:testSummaryData -Type Package
            
            $result | Should -Contain "| Statistic | Value |"
            $result | Should -Contain "| Total Packages | 5 |"
            $result | Should -Contain "| Average Line Coverage | 75.0% |"
            $result | Should -Contain "| Minimum Line Coverage | 55.0% |"
            $result | Should -Contain "| Maximum Line Coverage | 95.0% |"
        }

        It 'should calculate distribution correctly' {
            $result = New-CoverageSummaryTable -Data $script:testSummaryData -Type Package
            
            $result | Should -Contain "| Excellent Coverage (≥90%) | 1 |"  # 95%
            $result | Should -Contain "| Good Coverage (70-89%) | 2 |"     # 85%, 75%
            $result | Should -Contain "| Poor Coverage (<70%) | 2 |"       # 65%, 55%
        }
    }

    Context 'Empty data handling' {
        It 'should handle empty data gracefully' {
            $result = New-CoverageSummaryTable -Data @() -Type Package
            
            $result | Should -Be "*No data available*"
        }
    }
}