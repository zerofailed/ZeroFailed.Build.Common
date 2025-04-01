# <copyright file="cicd-server.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: When true, the version number will not be sent to the DevOps agent. Default is false.
$SkipSetCICDServerBuildNumber = property ZF_BUILD_SKIP_SET_CICD_SERVER_BUILDNUMBER $false

# Synopsis: Defines which of the GitVersion properties is used as the build server's build number. Default is "SemVer".
$GitVersionComponentForBuildNumber = property ZF_BUILD_GITVERSION_COMPONENT_FOR_BUILDNUMBER "SemVer"
