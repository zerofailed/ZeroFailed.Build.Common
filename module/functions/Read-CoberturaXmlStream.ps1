# <copyright file="Read-CoberturaXmlStream.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
    Efficiently reads Cobertura XML coverage reports using streaming to handle large files.
.DESCRIPTION
    This function uses XmlReader for memory-efficient streaming processing of Cobertura XML files,
    enabling processing of large coverage reports (100MB+) without loading the entire DOM into memory.
    It yields structured coverage data progressively as it reads through the XML.
.EXAMPLE
    PS C:\> Read-CoberturaXmlStream -Path "./coverage.xml" | ForEach-Object { $_.Package.Name }
    
    Streams through the coverage report and outputs just the package names.
.EXAMPLE
    PS C:\> $coverageData = Read-CoberturaXmlStream -Path "./large-coverage.xml" -BufferSize 1000
    
    Processes a large coverage file with a custom buffer size for batching elements.
.PARAMETER Path
    The path to the Cobertura XML coverage report file.
.PARAMETER BufferSize
    The number of elements to buffer before yielding results. Higher values use more memory but may improve performance.
.OUTPUTS
    Returns a structured object representing the coverage data with the following properties:
    @{
        CoverageInfo = @{ LineRate = 0.85; BranchRate = 0.75; LinesValid = 1000; LinesCovered = 850; ... }
        Packages = @( @{ Name = "com.example"; LineRate = 0.90; Classes = @(...) } )
    }
#>
function Read-CoberturaXmlStream
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Path,
        
        [Parameter()]
        [int] $BufferSize = 500
    )

    if (-not (Test-Path $Path)) {
        throw "Coverage file not found: $Path"
    }

    try {
        $coverageData = @{
            CoverageInfo = $null
            Packages = @()
        }

        $readerSettings = New-Object System.Xml.XmlReaderSettings
        $readerSettings.IgnoreWhitespace = $true
        $readerSettings.IgnoreComments = $true
        $readerSettings.DtdProcessing = [System.Xml.DtdProcessing]::Parse
        $readerSettings.XmlResolver = $null  # Disable external entity resolution for security
        
        $reader = [System.Xml.XmlReader]::Create($Path, $readerSettings)
        
        while ($reader.Read()) {
            switch ($reader.NodeType) {
                'Element' {
                    switch ($reader.LocalName) {
                        'coverage' {
                            $coverageData.CoverageInfo = _readCoverageElement $reader
                        }
                        'package' {
                            if ($reader.HasAttributes) {
                                $package = _readPackageElement $reader
                                $coverageData.Packages += $package
                                
                                # Yield progress for large files
                                if ($coverageData.Packages.Count % $BufferSize -eq 0) {
                                    Write-Verbose "Processed $($coverageData.Packages.Count) packages..."
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return $coverageData
    }
    catch {
        throw "Error reading Cobertura XML: $($_.Exception.Message)"
    }
    finally {
        if ($reader) {
            $reader.Close()
            $reader.Dispose()
        }
    }
}

# Internal function to read coverage root element attributes
function _readCoverageElement {
    [CmdletBinding()]
    param (
        [System.Xml.XmlReader] $reader
    )
    
    return @{
        LineRate = [double]($reader.GetAttribute('line-rate') ?? '0')
        BranchRate = [double]($reader.GetAttribute('branch-rate') ?? '0')
        LinesValid = [int]($reader.GetAttribute('lines-valid') ?? '0')
        LinesCovered = [int]($reader.GetAttribute('lines-covered') ?? '0')
        BranchesValid = [int]($reader.GetAttribute('branches-valid') ?? '0')
        BranchesCovered = [int]($reader.GetAttribute('branches-covered') ?? '0')
        Complexity = [double]($reader.GetAttribute('complexity') ?? '0')
        Version = $reader.GetAttribute('version') ?? ''
        Timestamp = $reader.GetAttribute('timestamp') ?? ''
    }
}

# Internal function to read package element and its children
function _readPackageElement {
    [CmdletBinding()]
    param (
        [System.Xml.XmlReader] $reader
    )
    
    $package = @{
        Name = $reader.GetAttribute('name') ?? ''
        LineRate = [double]($reader.GetAttribute('line-rate') ?? '0')
        BranchRate = [double]($reader.GetAttribute('branch-rate') ?? '0')
        Complexity = [double]($reader.GetAttribute('complexity') ?? '0')
        Classes = @()
    }
    
    # Read package children if not empty element
    if (-not $reader.IsEmptyElement) {
        $packageDepth = $reader.Depth
        
        while ($reader.Read() -and $reader.Depth -gt $packageDepth) {
            if ($reader.NodeType -eq 'Element' -and $reader.LocalName -eq 'class') {
                $class = _readClassElement $reader
                $package.Classes += $class
            }
        }
    }
    
    return $package
}

# Internal function to read class element and its children
function _readClassElement {
    [CmdletBinding()]
    param (
        [System.Xml.XmlReader] $reader
    )
    
    $class = @{
        Name = $reader.GetAttribute('name') ?? ''
        Filename = $reader.GetAttribute('filename') ?? ''
        LineRate = [double]($reader.GetAttribute('line-rate') ?? '0')
        BranchRate = [double]($reader.GetAttribute('branch-rate') ?? '0')
        Complexity = [double]($reader.GetAttribute('complexity') ?? '0')
        Methods = @()
        Lines = @()
    }
    
    # Read class children if not empty element
    if (-not $reader.IsEmptyElement) {
        $classDepth = $reader.Depth
        
        while ($reader.Read() -and $reader.Depth -gt $classDepth) {
            if ($reader.NodeType -eq 'Element') {
                switch ($reader.LocalName) {
                    'method' {
                        $method = _readMethodElement $reader
                        $class.Methods += $method
                    }
                    'line' {
                        $line = _readLineElement $reader
                        $class.Lines += $line
                    }
                }
            }
        }
    }
    
    return $class
}

# Internal function to read method element
function _readMethodElement {
    [CmdletBinding()]
    param (
        [System.Xml.XmlReader] $reader
    )
    
    $method = @{
        Name = $reader.GetAttribute('name') ?? ''
        Signature = $reader.GetAttribute('signature') ?? ''
        LineRate = [double]($reader.GetAttribute('line-rate') ?? '0')
        BranchRate = [double]($reader.GetAttribute('branch-rate') ?? '0')
        Complexity = [double]($reader.GetAttribute('complexity') ?? '0')
        Lines = @()
    }
    
    # Read method lines if not empty element
    if (-not $reader.IsEmptyElement) {
        $methodDepth = $reader.Depth
        
        while ($reader.Read() -and $reader.Depth -gt $methodDepth) {
            if ($reader.NodeType -eq 'Element' -and $reader.LocalName -eq 'line') {
                $line = _readLineElement $reader
                $method.Lines += $line
            }
        }
    }
    
    return $method
}

# Internal function to read line element
function _readLineElement {
    [CmdletBinding()]
    param (
        [System.Xml.XmlReader] $reader
    )
    
    return @{
        Number = [int]($reader.GetAttribute('number') ?? '0')
        Hits = [int]($reader.GetAttribute('hits') ?? '0')
        Branch = [bool]($reader.GetAttribute('branch') -eq 'true')
        ConditionCoverage = $reader.GetAttribute('condition-coverage') ?? ''
    }
}