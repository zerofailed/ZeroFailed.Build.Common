# <copyright file="Read-CoberturaXmlStream.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe 'Read-CoberturaXmlStream' {
    
    Context 'Valid Cobertura XML file' {
        BeforeAll {
            # Create a test XML file
            $testXmlContent = @'
<?xml version="1.0"?>
<!DOCTYPE coverage SYSTEM "coverage-loose.dtd"[]>
<coverage lines-valid="100" lines-covered="85" line-rate="0.85" branches-valid="20" branches-covered="15" branch-rate="0.75" timestamp="1755255009371" version="0.1" complexity="2.5">
  <sources>
    <source>/test/path</source>
  </sources>
  <packages>
    <package name="com.example.package1" line-rate="0.90" branch-rate="0.80" complexity="1.5">
      <classes>
        <class name="TestClass1.java" filename="TestClass1.java" line-rate="0.95" branch-rate="0.85" complexity="2.0">
          <methods>
            <method name="testMethod1" signature="()V" line-rate="1.0" branch-rate="1.0" complexity="1.0">
              <lines>
                <line number="10" hits="5" branch="false" />
                <line number="11" hits="3" branch="true" condition-coverage="50% (1/2)" />
              </lines>
            </method>
          </methods>
          <lines>
            <line number="10" hits="5" branch="false" />
            <line number="11" hits="3" branch="true" condition-coverage="50% (1/2)" />
            <line number="12" hits="0" branch="false" />
          </lines>
        </class>
      </classes>
    </package>
    <package name="com.example.package2" line-rate="0.75" branch-rate="0.65" complexity="3.0">
      <classes>
        <class name="TestClass2.java" filename="TestClass2.java" line-rate="0.80" branch-rate="0.70" complexity="2.5">
          <methods>
            <method name="testMethod2" signature="()I" line-rate="0.75" branch-rate="0.50" complexity="2.0">
              <lines>
                <line number="20" hits="2" branch="false" />
                <line number="21" hits="0" branch="false" />
              </lines>
            </method>
          </methods>
          <lines>
            <line number="20" hits="2" branch="false" />
            <line number="21" hits="0" branch="false" />
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@
            $script:testXmlPath = Join-Path $TestDrive 'test-coverage.xml'
            $testXmlContent | Out-File -FilePath $script:testXmlPath -Encoding utf8
        }

        It 'should read coverage root element correctly' {
            $result = Read-CoberturaXmlStream -Path $script:testXmlPath

            $result.CoverageInfo | Should -Not -BeNullOrEmpty
            $result.CoverageInfo.LineRate | Should -Be 0.85
            $result.CoverageInfo.BranchRate | Should -Be 0.75
            $result.CoverageInfo.LinesValid | Should -Be 100
            $result.CoverageInfo.LinesCovered | Should -Be 85
            $result.CoverageInfo.BranchesValid | Should -Be 20
            $result.CoverageInfo.BranchesCovered | Should -Be 15
            $result.CoverageInfo.Complexity | Should -Be 2.5
            $result.CoverageInfo.Version | Should -Be '0.1'
            $result.CoverageInfo.Timestamp | Should -Be '1755255009371'
        }

        It 'should read all packages correctly' {
            $result = Read-CoberturaXmlStream -Path $script:testXmlPath

            $result.Packages | Should -HaveCount 2
            $result.Packages[0].Name | Should -Be 'com.example.package1'
            $result.Packages[0].LineRate | Should -Be 0.90
            $result.Packages[0].BranchRate | Should -Be 0.80
            $result.Packages[0].Complexity | Should -Be 1.5
            
            $result.Packages[1].Name | Should -Be 'com.example.package2'
            $result.Packages[1].LineRate | Should -Be 0.75
            $result.Packages[1].BranchRate | Should -Be 0.65
            $result.Packages[1].Complexity | Should -Be 3.0
        }

        It 'should read classes within packages correctly' {
            $result = Read-CoberturaXmlStream -Path $script:testXmlPath

            $result.Packages[0].Classes | Should -HaveCount 1
            $class = $result.Packages[0].Classes[0]
            $class.Name | Should -Be 'TestClass1.java'
            $class.Filename | Should -Be 'TestClass1.java'
            $class.LineRate | Should -Be 0.95
            $class.BranchRate | Should -Be 0.85
            $class.Complexity | Should -Be 2.0
        }

        It 'should read methods within classes correctly' {
            $result = Read-CoberturaXmlStream -Path $script:testXmlPath

            $class = $result.Packages[0].Classes[0]
            $class.Methods | Should -HaveCount 1
            $method = $class.Methods[0]
            $method.Name | Should -Be 'testMethod1'
            $method.Signature | Should -Be '()V'
            $method.LineRate | Should -Be 1.0
            $method.BranchRate | Should -Be 1.0
            $method.Complexity | Should -Be 1.0
        }

        It 'should read lines within methods correctly' {
            $result = Read-CoberturaXmlStream -Path $script:testXmlPath

            $method = $result.Packages[0].Classes[0].Methods[0]
            $method.Lines | Should -HaveCount 2
            
            $line1 = $method.Lines[0]
            $line1.Number | Should -Be 10
            $line1.Hits | Should -Be 5
            $line1.Branch | Should -Be $false
            
            $line2 = $method.Lines[1]
            $line2.Number | Should -Be 11
            $line2.Hits | Should -Be 3
            $line2.Branch | Should -Be $true
            $line2.ConditionCoverage | Should -Be '50% (1/2)'
        }

        It 'should read lines within classes correctly' {
            $result = Read-CoberturaXmlStream -Path $script:testXmlPath

            $class = $result.Packages[0].Classes[0]
            $class.Lines | Should -HaveCount 3
            
            $line1 = $class.Lines[0]
            $line1.Number | Should -Be 10
            $line1.Hits | Should -Be 5
            
            $line3 = $class.Lines[2]
            $line3.Number | Should -Be 12
            $line3.Hits | Should -Be 0
        }
    }

    Context 'File not found' {
        It 'should throw an error when file does not exist' {
            { Read-CoberturaXmlStream -Path '/nonexistent/path.xml' } | Should -Throw "*Coverage file not found*"
        }
    }

    Context 'Invalid XML file' {
        BeforeAll {
            $invalidXmlContent = @'
<?xml version="1.0"?>
<coverage lines-valid="100" lines-covered="85">
  <packages>
    <package name="test">
      <unclosed-tag>
  </packages>
</coverage>
'@
            $script:invalidXmlPath = Join-Path $TestDrive 'invalid-coverage.xml'
            $invalidXmlContent | Out-File -FilePath $script:invalidXmlPath -Encoding utf8
        }

        It 'should throw an error for malformed XML' {
            { Read-CoberturaXmlStream -Path $script:invalidXmlPath } | Should -Throw "*Error reading Cobertura XML*"
        }
    }

    Context 'Empty coverage file' {
        BeforeAll {
            $emptyXmlContent = @'
<?xml version="1.0"?>
<coverage lines-valid="0" lines-covered="0" line-rate="0" branches-valid="0" branches-covered="0" branch-rate="0" timestamp="0" version="0.1">
  <packages>
  </packages>
</coverage>
'@
            $script:emptyXmlPath = Join-Path $TestDrive 'empty-coverage.xml'
            $emptyXmlContent | Out-File -FilePath $script:emptyXmlPath -Encoding utf8
        }

        It 'should handle empty coverage reports' {
            $result = Read-CoberturaXmlStream -Path $script:emptyXmlPath

            $result.CoverageInfo | Should -Not -BeNullOrEmpty
            $result.CoverageInfo.LinesValid | Should -Be 0
            $result.CoverageInfo.LinesCovered | Should -Be 0
            $result.Packages | Should -HaveCount 0
        }
    }

    Context 'Custom buffer size' {
        BeforeAll {
            # Create XML with multiple packages
            $multiPackageXml = @'
<?xml version="1.0"?>
<coverage lines-valid="300" lines-covered="255" line-rate="0.85" branches-valid="60" branches-covered="45" branch-rate="0.75" timestamp="1755255009371" version="0.1">
  <packages>
    <package name="package1" line-rate="0.90" branch-rate="0.80">
      <classes></classes>
    </package>
    <package name="package2" line-rate="0.85" branch-rate="0.75">
      <classes></classes>
    </package>
    <package name="package3" line-rate="0.80" branch-rate="0.70">
      <classes></classes>
    </package>
  </packages>
</coverage>
'@
            $script:multiPackageXmlPath = Join-Path $TestDrive 'multi-package-coverage.xml'
            $multiPackageXml | Out-File -FilePath $script:multiPackageXmlPath -Encoding utf8
        }

        It 'should process with custom buffer size' {
            $result = Read-CoberturaXmlStream -Path $script:multiPackageXmlPath -BufferSize 2

            $result.Packages | Should -HaveCount 3
            $result.Packages[0].Name | Should -Be 'package1'
            $result.Packages[1].Name | Should -Be 'package2'
            $result.Packages[2].Name | Should -Be 'package3'
        }
    }
}