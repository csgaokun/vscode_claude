param(
    [string]$QtRoot = 'C:\Qt\Qt5.12.12\5.12.12\msvc2017_64',
    [string]$BuildRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path '_build\msvc2017_64_qt5.12.12'),
    [string]$ExePath,
    [string]$Arguments = '',
    [switch]$EnableVerboseQtLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common-env.ps1')

if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $installedExe = Join-Path $BuildRoot 'install\qt-hldplugin\bin\qthldplugin.exe'
    $buildExe = Join-Path $BuildRoot 'build\bin\qthldplugin.exe'
    $ExePath = if (Test-Path -LiteralPath $installedExe) { $installedExe } else { $buildExe }
}

Write-Step -Message 'Prepare runtime environment'
Import-Vs2017Environment
Import-QtEnvironment -QtRoot $QtRoot
Assert-FileExists -Path $ExePath

$logsDir = Join-Path $BuildRoot 'logs'
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$runtimeLog = Join-Path $logsDir ("$runId-70-runtime.log")

if ($EnableVerboseQtLogs) {
    $env:QT_LOGGING_RULES = '*.debug=true;qt.*.debug=true'
    $env:QT_FORCE_STDERR_LOGGING = '1'
}

$workDir = Split-Path -Parent $ExePath
$cmd = "cd /d `"$workDir`" && `"$ExePath`" $Arguments"

Invoke-LoggedCommand -StepName 'Run Qt Hldplugin' -LogPath $runtimeLog -Command $cmd

Write-Step -Message 'Runtime finished'
Write-Host "Runtime log: $runtimeLog"
