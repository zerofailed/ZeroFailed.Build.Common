# <copyright file="ConvertFrom-CoberturaXml.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    . $PSCommandPath.Replace('ConvertFrom-CoberturaXml.Tests.ps1','Read-CoberturaXmlStream.ps1')
    . $PSCommandPath.Replace('ConvertFrom-CoberturaXml.Tests.ps1','New-CoverageSummary.ps1')
    . $PSCommandPath.Replace('ConvertFrom-CoberturaXml.Tests.ps1','New-CoverageMarkdownTable.ps1')
    . $PSCommandPath.Replace('ConvertFrom-CoberturaXml.Tests.ps1','Format-CoveragePercentage.ps1')
}

Describe 'ConvertFrom-CoberturaXml' {
    
    BeforeAll {
        # Create a comprehensive test XML file
        $script:testXmlContent = @'
<?xml version="1.0"?>
<!DOCTYPE coverage SYSTEM "coverage-loose.dtd"[]>
<coverage lines-valid="1000" lines-covered="850" line-rate="0.85" branches-valid="200" branches-covered="150" branch-rate="0.75" timestamp="1755255009371" version="0.1" complexity="4.5">
  <sources>
    <source>/src/main/java</source>
  </sources>
  <packages>
    <package name="com.example.core" line-rate="0.90" branch-rate="0.85" complexity="3.2">
      <classes>
        <class name="CoreService.java" filename="com/example/core/CoreService.java" line-rate="0.95" branch-rate="0.90" complexity="2.5">
          <methods>
            <method name="processData" signature="(Ljava/lang/String;)V" line-rate="1.0" branch-rate="1.0" complexity="1.0">
              <lines>
                <line number="25" hits="10" branch="false" />
                <line number="26" hits="8" branch="true" condition-coverage="100% (2/2)" />
                <line number="27" hits="5" branch="false" />
              </lines>
            </method>
            <method name="validateInput" signature="(Ljava/lang/Object;)Z" line-rate="0.85" branch-rate="0.75" complexity="3.0">
              <lines>
                <line number="35" hits="15" branch="true" condition-coverage="75% (3/4)" />
                <line number="36" hits="12" branch="false" />
                <line number="37" hits="0" branch="false" />
              </lines>
            </method>
          </methods>
          <lines>
            <line number="25" hits="10" branch="false" />
            <line number="26" hits="8" branch="true" condition-coverage="100% (2/2)" />
            <line number="27" hits="5" branch="false" />
            <line number="35" hits="15" branch="true" condition-coverage="75% (3/4)" />
            <line number="36" hits="12" branch="false" />
            <line number="37" hits="0" branch="false" />
          </lines>
        </class>
        <class name="CoreUtility.java" filename="com/example/core/CoreUtility.java" line-rate="0.80" branch-rate="0.70" complexity="2.8">
          <methods>
            <method name="helperMethod" signature="()I" line-rate="0.80" branch-rate="0.60" complexity="2.5">
              <lines>
                <line number="15" hits="5" branch="false" />
                <line number="16" hits="0" branch="false" />
              </lines>
            </method>
          </methods>
          <lines>
            <line number="15" hits="5" branch="false" />
            <line number="16" hits="0" branch="false" />
          </lines>
        </class>
      </classes>
    </package>
    <package name="com.example.util" line-rate="0.75" branch-rate="0.60" complexity="5.8">
      <classes>
        <class name="StringHelper.java" filename="com/example/util/StringHelper.java" line-rate="0.75" branch-rate="0.60" complexity="5.8">
          <methods>
            <method name="formatString" signature="(Ljava/lang/String;)Ljava/lang/String;" line-rate="0.75" branch-rate="0.60" complexity="5.8">
              <lines>
                <line number="10" hits="3" branch="true" condition-coverage="50% (1/2)" />
                <line number="11" hits="2" branch="false" />
                <line number="12" hits="0" branch="false" />
              </lines>
            </method>
          </methods>
          <lines>
            <line number="10" hits="3" branch="true" condition-coverage="50% (1/2)" />
            <line number="11" hits="2" branch="false" />
            <line number="12" hits="0" branch="false" />
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@
        $script:testXmlPath = Join-Path $TestDrive 'test-coverage.xml'
        $script:testXmlContent | Out-File -FilePath $script:testXmlPath -Encoding utf8
        
        # Create a simple XML for basic tests
        $script:simpleXmlContent = @'
<?xml version="1.0"?>
<coverage lines-valid="100" lines-covered="80" line-rate="0.80" branches-valid="20" branches-covered="15" branch-rate="0.75" timestamp="1755255009371" version="0.1" complexity="2.0">
  <packages>
    <package name="simple.package" line-rate="0.80" branch-rate="0.75" complexity="2.0">
      <classes>
        <class name="SimpleClass.java" filename="SimpleClass.java" line-rate="0.80" branch-rate="0.75" complexity="2.0">
          <methods></methods>
          <lines></lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@
        $script:simpleXmlPath = Join-Path $TestDrive 'simple-coverage.xml'
        $script:simpleXmlContent | Out-File -FilePath $script:simpleXmlPath -Encoding utf8
    }

    Context 'Basic functionality' {
        It 'should convert XML to markdown and return as string' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match "# Code Coverage Report"
            $result | Should -Match "## Executive Summary"
            $result | Should -Match "## Overall Coverage Metrics"
            $result | Should -Match "## Package Coverage"
            $result | Should -Match "## Coverage Insights"
        }

        It 'should include overall coverage metrics' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Match "85\.0%.*850 of 1000 lines covered"
            $result | Should -Match "75\.0%.*150 of 200 branches covered"
            $result | Should -Match "Packages Analyzed.*2"
        }

        It 'should include package breakdown' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Match "com\.example\.core"
            $result | Should -Match "com\.example\.util"
            $result | Should -Match "90\.0%"  # Core package coverage
            $result | Should -Match "75\.0%"  # Util package coverage
        }

        It 'should include class details for packages' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Match "CoreService\.java"
            $result | Should -Match "CoreUtility\.java"
            $result | Should -Match "StringHelper\.java"
        }
    }

    Context 'Output to file' {
        It 'should write markdown to specified file' {
            $outputPath = Join-Path $TestDrive 'output-report.md'
            
            ConvertFrom-CoberturaXml -Path $script:testXmlPath -OutputPath $outputPath
            
            $outputPath | Should -Exist
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Not -BeNullOrEmpty
            $content | Should -Match "# Code Coverage Report"
        }

        It 'should handle output path with existing parent directory' {
            $outputDir = Join-Path $TestDrive 'nested'
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            $outputPath = Join-Path $outputDir 'report.md'
            
            ConvertFrom-CoberturaXml -Path $script:testXmlPath -OutputPath $outputPath
            
            $outputPath | Should -Exist
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "# Code Coverage Report"
        }
    }

    Context 'Method details parameter' {
        It 'should include method details when IncludeMethodDetails is specified' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath -IncludeMethodDetails
            
            $result | Should -Match "#### Class: CoreService\.java"
            $result | Should -Match "processData"
            $result | Should -Match "validateInput"
            $result | Should -Match "helperMethod"
            $result | Should -Match "formatString"
        }

        It 'should not include method details by default' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Not -Match "#### Class:"
            $result | Should -Not -Match "processData"
            $result | Should -Not -Match "validateInput"
        }
    }

    Context 'Summary only parameter' {
        It 'should generate only summary when SummaryOnly is specified' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath -SummaryOnly
            
            $result | Should -Match "# Code Coverage Report"
            $result | Should -Match "## Executive Summary"
            $result | Should -Match "## Overall Coverage Metrics"
            $result | Should -Not -Match "## Package Coverage"
            $result | Should -Not -Match "## Coverage Insights"
        }
    }

    Context 'Custom parameters' {
        It 'should use custom title' {
            $customTitle = "My Custom Coverage Report"
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath -Title $customTitle
            
            $result | Should -Match "# $customTitle"
        }

        It 'should use custom minimum coverage threshold' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath -MinimumCoverage 80
            
            # With 75% util package coverage and 80% threshold, should show warning indicators
            $result | Should -Match "⚠️.*75\.0%"
        }
    }

    Context 'Error handling' {
        It 'should throw meaningful error when file does not exist' {
            { ConvertFrom-CoberturaXml -Path '/nonexistent/file.xml' } | Should -Throw "*Error converting Cobertura XML to Markdown*"
        }

        It 'should handle malformed XML gracefully' {
            $malformedXml = @'
<?xml version="1.0"?>
<coverage lines-valid="100">
  <unclosed-tag>
    <package name="test">
</coverage>
'@
            $malformedPath = Join-Path $TestDrive 'malformed.xml'
            $malformedXml | Out-File -FilePath $malformedPath -Encoding utf8
            
            { ConvertFrom-CoberturaXml -Path $malformedPath } | Should -Throw "*Error converting Cobertura XML to Markdown*"
        }
    }

    Context 'Coverage insights generation' {
        It 'should generate positive assessment for good coverage' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Match "Good Coverage|Excellent.*coverage"
            $result | Should -Match "Overall line coverage is 85\.0%"
        }

        It 'should provide recommendations' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            $result | Should -Match "### Recommendations"
            $result | Should -Match "Maintenance.*Review and maintain test coverage"
        }

        It 'should identify packages requiring attention' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath -MinimumCoverage 80
            
            $result | Should -Match "Packages requiring attention"
            $result | Should -Match "com\.example\.util.*75\.0% coverage"
        }
    }

    Context 'Integration with supporting functions' {
        It 'should properly integrate Read-CoberturaXmlStream' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            # Verify that coverage data was properly parsed
            $result | Should -Match "1,000"    # Lines valid formatted with comma
            $result | Should -Match "850"      # Lines covered
            $result | Should -Match "4\.5"     # Complexity
        }

        It 'should properly integrate New-CoverageSummary' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            # Verify executive summary elements
            $result | Should -Match "📊.*Overall Line Coverage"
            $result | Should -Match "📈.*Branch Coverage"
            $result | Should -Match "📦.*Packages Analyzed"
            $result | Should -Match "🔧.*Code Complexity"
        }

        It 'should properly integrate New-CoverageMarkdownTable' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            # Verify table formatting
            $result | Should -Match "\| Package \| Line Coverage \| Branch Coverage \| Classes \| Complexity \|"
            $result | Should -Match "\|---------|---------------|-----------------|---------|------------|"
        }

        It 'should properly integrate Format-CoveragePercentage' {
            $result = ConvertFrom-CoberturaXml -Path $script:testXmlPath
            
            # Verify visual indicators are present
            $result | Should -Match "✅|✔️|⚠️"
        }
    }

    Context 'Edge cases' {
        It 'should handle empty packages gracefully' {
            $emptyXml = @'
<?xml version="1.0"?>
<coverage lines-valid="0" lines-covered="0" line-rate="0" branches-valid="0" branches-covered="0" branch-rate="0" timestamp="0" version="0.1" complexity="0">
  <packages>
  </packages>
</coverage>
'@
            $emptyPath = Join-Path $TestDrive 'empty.xml'
            $emptyXml | Out-File -FilePath $emptyPath -Encoding utf8
            
            $result = ConvertFrom-CoberturaXml -Path $emptyPath
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "# Code Coverage Report"
            $result | Should -Match "0 of 0 lines covered"
        }

        It 'should handle missing timestamp gracefully' {
            $noTimestampXml = @'
<?xml version="1.0"?>
<coverage lines-valid="100" lines-covered="80" line-rate="0.80" branches-valid="20" branches-covered="15" branch-rate="0.75" version="0.1">
  <packages>
  </packages>
</coverage>
'@
            $noTimestampPath = Join-Path $TestDrive 'no-timestamp.xml'
            $noTimestampXml | Out-File -FilePath $noTimestampPath -Encoding utf8
            
            $result = ConvertFrom-CoberturaXml -Path $noTimestampPath
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "Generated on:"
            $result | Should -Not -Match "Coverage Date:"
        }
    }
}