## bombardier: Fast cross-platform HTTP benchmarking tool written in Go (Chocolatey package)

[![Build Status](https://willh.visualstudio.com/bombardier-chocolatey/_apis/build/status/bombardier-chocolatey-CI?branchName=master)](https://willh.visualstudio.com/bombardier-chocolatey/_build/latest?definitionId=58&branchName=master)

Project Repo: <https://github.com/codesenberg/bombardier>

### How to build package

```sh
choco pack
```

### How to test install locally

```sh
choco install bombardier -d -s .
```

### How to test uninstall locally

```sh
choco uninstall bombardier -d -s .
```

### How to publish new version

```sh
choco push bombardier.X.Y.Z.nupkg --source https://push.chocolatey.org/
```

### How to update this package

1. Edit `tools/chocolateyinstall.ps1`

    * `$url`
    * `$url64`
    * `checksum`
    * `checksum64`

2. Edit `bombardier.nuspec`

    * Update `<version>`
    * Update `<releaseNotes>` (reference from [here](https://raw.githubusercontent.com/go-gitea/gitea/master/CHANGELOG.md))

3. Test install

    Open Command Prompt with Administrative right

    ```sh
    choco pack
    choco install bombardier -d -s . -y
    choco uninstall bombardier -d -s .
    ```

4. Publish to Chocolatey Gallery

    ```sh
    choco push bombardier.X.Y.Z.nupkg --source https://push.chocolatey.org/
    ```

### How to build latest version of bombardier chocolatey package

```sh
.\build.ps1
```

This will generate a `publish.ps1` file to help publish to the Chocolatey Gallery.
