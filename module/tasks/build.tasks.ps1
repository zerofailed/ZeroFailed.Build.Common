# <copyright file="build.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/build.properties.ps1

# Synopsis: Ensures the packages output directory exists
task EnsurePackagesDir -After InitCore {
    # Ensure we resolve a relative path for $PackagesDir now, rather than letting it be resolved by downstream tooling
    # For example, 'dotnet pack' will resolve it relative to a given project which is not what we want.
    $script:PackagesDir = [IO.Path]::IsPathRooted($PackagesDir) ? $PackagesDir : (Join-Path $here $PackagesDir)

    if (!(Test-Path $PackagesDir)) {
        New-Item -Path $PackagesDir -ItemType Directory | Out-Null
    }
}

# These tasks will send a message to the build server to indicate that the phase has
# completed successfully, which will be displayed in the build summary screen.
# (i.e. visible without having to drill into the logs)

# Synopsis: Sends a message to the build server to indicate that the build phase has completed successfully.
task sendCompileOkMessageToCICDServer -If {$SendPhaseCompletionMessagesToCICDServer -and $IsRunningOnCICDServer} -After Build DetectCICDServer,{
    if ($IsGitHubActions) {
        Write-Host ("::notice title=Compile OK::Compile phase completed successfully")
    }
    elseif ($IsAzureDevOps) {
        # TODO: Determine whether any of the available options make the message suitably visible in the build summary
    }
}

# Synopsis: Sends a message to the build server to indicate that the analysis phase has completed successfully.
task sendAnalysisOkMessageToCICDServer -If {$SendPhaseCompletionMessagesToCICDServer -and $IsRunningOnCICDServer} -After Analysis DetectCICDServer,{
    if ($IsGitHubActions) {
        Write-Host ("::notice title=Analysis OK::Analysis phase completed successfully")
    }
    elseif ($IsAzureDevOps) {
        # TODO: Determine whether any of the available options make the message suitably visible in the build summary
    }
}

# Synopsis: Sends a message to the build server to indicate that the test phase has completed successfully.
task sendTestOkMessageToCICDServer -If {$SendPhaseCompletionMessagesToCICDServer -and $IsRunningOnCICDServer} -After Test DetectCICDServer,{
    if ($IsGitHubActions) {
        Write-Host ("::notice title=Test OK::Test phase completed successfully")
    }
    elseif ($IsAzureDevOps) {
        # TODO: Determine whether any of the available options make the message suitably visible in the build summary
    }
}

# Synopsis: Sends a message to the build server to indicate that the package phase has completed successfully.
task sendPackageOkMessageToCICDServer -If {$SendPhaseCompletionMessagesToCICDServer -and $IsRunningOnCICDServer} -After Package DetectCICDServer,{
    if ($IsGitHubActions) {
        Write-Host ("::notice title=Package OK::Package phase completed successfully")
    }
    elseif ($IsAzureDevOps) {
        # TODO: Determine whether any of the available options make the message suitably visible in the build summary
    }
}

# Synopsis: Sends a message to the build server to indicate that the publish phase has completed successfully.
task sendPublishOkMessageToCICDServer -If {$SendPhaseCompletionMessagesToCICDServer -and $IsRunningOnCICDServer} -After Publish DetectCICDServer,{
    if ($IsGitHubActions) {
        Write-Host ("::notice title=Publish OK::Publish phase completed successfully")
    }
    elseif ($IsAzureDevOps) {
        # TODO: Determine whether any of the available options make the message suitably visible in the build summary
    }
}
