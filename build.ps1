$LatestJSON = ((Invoke-WebRequest "https://api.github.com/repos/codesenberg/bombardier/releases/latest").Content | ConvertFrom-Json)

$ReleaseNotes  = $LatestJSON.body.Replace("`r`n`r`n", "`r`n").Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")

$LatestVersion = $LatestJSON.tag_name -replace "v" -replace ""
$LatestVersion | Out-File -FilePath LatestVersion.txt -Encoding UTF8

$LatestChocoVersion = "0.0.0"
$AllChocoVersions = (choco list bombardier -r --all | C:\Windows\System32\sort.exe /r)

if ($AllChocoVersions.GetType().FullName -eq 'System.String') {
  $LatestChocoVersion = ($AllChocoVersions -split '\|')[1]
} else {
  $LatestChocoVersion = ($AllChocoVersions[0] -split '\|')[1]
}

$LatestChocoVersion | Out-File -FilePath LatestChocoVersion.txt -Encoding UTF8

$x86_link = $LatestJSON.assets | ForEach-Object -Process { if ($_.name -eq 'bombardier-windows-386.exe'){ $_.browser_download_url } }
$x64_link = $LatestJSON.assets | ForEach-Object -Process { if ($_.name -eq 'bombardier-windows-amd64.exe'){ $_.browser_download_url } }

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -OutFile bombardier-windows-386.exe -Uri $x86_link
Invoke-WebRequest -OutFile bombardier-windows-amd64.exe -Uri $x64_link
$ProgressPreference = 'Continue'

$x86_sha256 = (Get-FileHash .\bombardier-windows-386.exe).Hash
$x64_sha256 = (Get-FileHash .\bombardier-windows-amd64.exe).Hash

Remove-Item .\bombardier-windows-386.exe
Remove-Item .\bombardier-windows-amd64.exe

@"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>bombardier</id>
    <version>$LatestVersion</version>
    <packageSourceUrl>https://github.com/doggy8088/bombardier-chocolatey</packageSourceUrl>
    <owners>Will 保哥</owners>
    <title>Bombardier</title>
    <authors>Bombardier</authors>
    <projectUrl>https://github.com/codesenberg/bombardier</projectUrl>
    <iconUrl>https://avatars1.githubusercontent.com/u/6357982?s=40&amp;v=4</iconUrl>
    <copyright>The Bombardier Authors</copyright>
    <licenseUrl>https://github.com/codesenberg/bombardier/blob/master/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <projectSourceUrl>https://github.com/codesenberg/bombardier</projectSourceUrl>
    <docsUrl>https://github.com/codesenberg/bombardier/wiki</docsUrl>
    <bugTrackerUrl>https://github.com/codesenberg/bombardier/issues</bugTrackerUrl>
    <tags>bombardier http go</tags>
    <summary>Fast cross-platform HTTP benchmarking tool written in Go</summary>
    <description>Fast cross-platform HTTP benchmarking tool written in Go and published under the MIT license.</description>
    <releaseNotes>$ReleaseNotes</releaseNotes>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@ | Out-File -FilePath bombardier.nuspec -Encoding UTF8

@"

`$ErrorActionPreference = 'Stop';

`$packageName= 'bombardier'
`$toolsDir   = "`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)"
`$url        = '$x86_link'
`$url64      = '$x64_link'
`$toolsDir   = "`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)"

`$packageArgs = @{
  packageName   = `$packageName

  url           = `$url
  url64bit      = `$url64

  softwareName  = 'bombardier'

  checksum      = '$x86_sha256'
  checksumType  = 'sha256'
  checksum64    = '$x64_sha256'
  checksumType64= 'sha256'

  fileFullPath  = "`$toolsDir\bombardier.exe"

  validExitCodes= @(0)
}

Get-ChocolateyWebFile @packageArgs
"@ | Out-File -FilePath tools\chocolateyinstall.ps1 -Encoding UTF8

choco pack

# choco install bombardier -d -s . -y
# choco uninstall bombardier -d -s .

@"
Set-ExecutionPolicy Unrestricted -Force
Install-Module -Name PoshSemanticVersion -Force

`$LatestChocoVersion = Get-Content LatestChocoVersion.txt
`$LatestVersion = Get-Content LatestVersion.txt

# Write-Output LatestChocoVersion = `$LatestChocoVersion
# Write-Output LatestVersion = `$LatestVersion

`$Precedence = (Compare-SemanticVersion -ReferenceVersion `$LatestChocoVersion -DifferenceVersion `$LatestVersion).Precedence;

if (`$Precedence -eq '>' -or `$Precedence -eq '=')
{
  Write-Output "因為 Chocolatey 的 bombardier 套件版本(`$LatestChocoVersion) 大於等於 bombardier `$LatestVersion 版本，因此不需要發行套件！"
  Write-Output "##vso[task.setvariable variable=BombardierVersion]canceled"
  echo "##vso[task.complete result=Canceled;]DONE"
  Exit 0
}
else
{
  Write-Output "##vso[task.setvariable variable=BombardierVersion]${LatestVersion}"
  Write-Output "準備發行 bombardier `$LatestVersion 版本到 Chocolatey Gallery"
  choco push bombardier.`$LatestVersion.nupkg --source https://push.chocolatey.org/ --key=#{CHOCO_APIKEY}#
}
"@ | Out-File -FilePath publish.ps1 -Encoding UTF8
