# ZeroFailed.Build.Common - Reference Sheet

<!-- START_GENERATED_HELP -->

## Build

This group contains general build process related functionality.

### Properties

| Name                                      | Default Value | ENV Override                         | Description                                                                                                    |
| ----------------------------------------- | ------------- | ------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `CleanBuild`                              | $false        | `ZF_BUILD_CLEAN`                     | When true, the build process will clean intermediate & output directories before starting the build.           |
| `SendPhaseCompletionMessagesToCICDServer` | $true         | `ZF_BUILD_PHASE_COMPLETION_MESSAGES` | When true (and running on a CI/CD server), the build process will send phase completion messages to the agent. |

### Tasks

| Name                | Description                                  |
| ------------------- | -------------------------------------------- |
| `EnsurePackagesDir` | Ensures the packages output directory exists |

## Cicd-server

This group group include features for build process related CI/CD server integration.

### Properties

| Name                                | Default Value | ENV Override                                    | Description                                                                            |
| ----------------------------------- | ------------- | ----------------------------------------------- | -------------------------------------------------------------------------------------- |
| `GitVersionComponentForBuildNumber` | "SemVer"      | `ZF_BUILD_GITVERSION_COMPONENT_FOR_BUILDNUMBER` | Defines which of the GitVersion properties is used as the build server's build number. |
| `SkipSetCICDServerBuildNumber`      | $false        | `ZF_BUILD_SKIP_SET_CICD_SERVER_BUILDNUMBER`     | When true, the version number will not be sent to the DevOps agent.                    |

### Tasks

| Name                                | Description                                                                                                                    |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `sendAnalysisOkMessageToCICDServer` | Sends a message to the build server to indicate that the analysis phase has completed successfully. NOTE: GitHub Actions only. |
| `sendCompileOkMessageToCICDServer`  | Sends a message to the build server to indicate that the build phase has completed successfully. NOTE: GitHub Actions only.    |
| `sendPackageOkMessageToCICDServer`  | Sends a message to the build server to indicate that the package phase has completed successfully. NOTE: GitHub Actions only.  |
| `sendPublishOkMessageToCICDServer`  | Sends a message to the build server to indicate that the publish phase has completed successfully. NOTE: GitHub Actions only.  |
| `sendTestOkMessageToCICDServer`     | Sends a message to the build server to indicate that the test phase has completed successfully. NOTE: GitHub Actions only.     |
| `SetCICDServerBuildNumber`          | Inform the DevOps agent of the current version number. NOTE: AzureDevOps only.                                                 |

## Versioning

This group provides automated versioning functionality.  Currently it supports this using the [GitVersion](https://github.com/GitTools/GitVersion) tool.

### Properties

| Name                    | Default Value      | ENV Override                       | Description                                                                                                                                                                                            |
| ----------------------- | ------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GitVersion`            | @{}                | `ZF_BUILD_GITVERSION_OVERRIDE`     | When defined, the value will used as an override of the GitVersion output. This can be useful when you want to force a particular version tag unrelated to the current branch etc. Not set by default. |
| `GitVersionConfigPath`  | "./GitVersion.yml" | `ZF_BUILD_GITVERSION_CONFIG_PATH`  | Path to the GitVersion configuration file. Default is a "GitVersion.yml" file alongside the running script.                                                                                            |
| `GitVersionToolVersion` | "5.8.0"            | `ZF_BUILD_GITVERSION_TOOL_VERSION` | The version of the GitVersion tool to use.                                                                                                                                                             |
| `SkipVersion`           | $false             | `ZF_BUILD_SKIP_VERSIONING`         | When true, the versioning tasks will be skipped.                                                                                                                                                       |
| `UseGitVersion`         | $true              | `ZF_BUILD_USE_GITVERSION`          | When true, the GitVersion tool will be used to determine the version number.                                                                                                                           |

### Tasks

| Name         | Description         |
| ------------ | ------------------- |
| `GitVersion` | Run GitVersion tool |


<!-- END_GENERATED_HELP -->
