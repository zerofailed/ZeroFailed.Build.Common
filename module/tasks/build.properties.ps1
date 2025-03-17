# <copyright file="build.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: When true, the build process will clean intermediate & output directories before starting the build.
$CleanBuild = property ZF_CleanBuild $false

# Synopsis: The directory path where packages produced by the build will be placed.
$PackagesDir ??= property ZF_PackagesDir '_packages'

# Synopsis: The directory path where code coverage files produced by the build will be placed.
$CoverageDir ??= property ZF_CoverageDir '_codeCoverage'
$CoverageDir = [IO.Path]::IsPathRooted($CoverageDir) ? $CoverageDir : (Join-Path $here $CoverageDir)

# Synopsis: When true (and running on a DevOps agent), the build process will send phase completion messages to the agent.
$SendPhaseCompletionMessagesToCICDServer = property ZF_SendPhaseCompletionMessagesToCICDServer $true
