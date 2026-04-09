param(
    [string]$QtRoot = 'C:\Qt\Qt5.12.12\5.12.12\msvc2017_64',
    [string]$SourceDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$BuildRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path '_build\msvc2017_64_qt5.12.12'),
    [ValidateSet('Release', 'RelWithDebInfo', 'Debug')][string]$BuildType = 'RelWithDebInfo'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common-env.ps1')

Write-Step -Message 'Prepare publish environment'
Import-Vs2017Environment
Import-QtEnvironment -QtRoot $QtRoot

$buildDir = Join-Path $BuildRoot 'build'
$installDir = Join-Path $BuildRoot 'install\qt-creator'
$artifactsDir = Join-Path $BuildRoot 'artifacts'
$logsDir = Join-Path $BuildRoot 'logs'

New-Item -ItemType Directory -Force -Path $artifactsDir, $logsDir | Out-Null

$runId = Get-Date -Format 'yyyyMMdd-HHmmss'

$deployScript = Join-Path $SourceDir 'scripts\deployqt.py'
$installedExe = Join-Path $installDir 'bin\qtcreator.exe'
$buildExe = Join-Path $buildDir 'bin\qtcreator.exe'
$qtcreatorExe = if (Test-Path -LiteralPath $installedExe) { $installedExe } else { $buildExe }
$qmakeExe = Join-Path $QtRoot 'bin\qmake.exe'

Assert-FileExists -Path $deployScript
Assert-FileExists -Path $qtcreatorExe
Assert-FileExists -Path $qmakeExe

$logDeploy = Join-Path $logsDir ("$runId-50-deploy.log")
$logPackage = Join-Path $logsDir ("$runId-60-package.log")

$deployCmd = "cd /d `"$buildDir`" && python -u `"$deployScript`" -i `"$qtcreatorExe`" `"$qmakeExe`""
Invoke-LoggedCommand -StepName 'Deploy Qt runtime' -LogPath $logDeploy -Command $deployCmd

$packageZip = Join-Path $artifactsDir ("qtcreator-msvc2017-qt5.12.12-{0}.zip" -f $BuildType.ToLowerInvariant())
if (Test-Path -LiteralPath $packageZip) {
    Remove-Item -LiteralPath $packageZip -Force
}

Write-Step -Message 'Create publish archive'
$packageSource = if (Test-Path -LiteralPath $installedExe) { $installDir } else { $buildDir }
Compress-Archive -Path (Join-Path $packageSource '*') -DestinationPath $packageZip -CompressionLevel Optimal
"Package: $packageZip" | Out-File -FilePath $logPackage -Encoding utf8

Write-Step -Message 'Publish completed'
Write-Host "Artifact: $packageZip"
Write-Host "Logs    : $logsDir"
