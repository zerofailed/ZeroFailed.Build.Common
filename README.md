# ZeroFailed.Build.Common

A [ZeroFailed](https://github.com/endjin/ZeroFailed) extension containing general purpose features that support build processes across a variety of technology stacks and toolchains.

## Features Overview

| Component Type | Included | Notes               |
|----------------|----------|---------------------|
| Functions      | no       |  |
| Tasks          | yes      |  |
| Processes      | yes      | Includes a generic logical build process designed to be integrated with by other extensions that provide the actual build functionality. |

For more information about the different component types, please refer to the [ZeroFailed documentation](https://github.com/zerofailed/ZeroFailed/blob/main/README.md#extensions).

This extension consists of the following feature groups:

- General Build

## Processes

### build.process.ps1

To use this process ensure that your reference to this extension includes the `Process` property as below:

```
$zeroFailedExtensions = @(
    @{
        Name = "ZeroFailed.DevOps.Common"
        Process = "tasks/build.process.ps1"
    }
)
```

This models an opinionated abstract build process that is intended to be generic enough to support a variety of different technology stacks and toolchains, as can be seen in the diagram below.

```mermaid
graph LR
    init
    version
    build
    test
    analysis
    package
    publish

    init --> version
    version --> build
    build --> test
    test --> analysis
    analysis --> package
    package --> publish
```

Each of the above stages has `Pre` & `Post` tasks which are intended as extensibility points that can be used to customise the process as required. (e.g. `PreBuild`, `PostBuild`, `PrePackage` etc.)  For convenience, it also provides `RunFirst` & `RunLast` tasks that can be used when necessary.

Typically, these extensibility tasks will be referenced at the end of the script that runs your automated process. For example, below we see a custom task called `MyCustomPackagingTask` that is set as a dependency of the `PrePackage` task provided by this extension; this has the effect of running the custom task before other packaging-related tasks.

```
task PrePackage MyCustomPackagingTask

task MyCustomPackagingTask {
    # Do something special
}
```