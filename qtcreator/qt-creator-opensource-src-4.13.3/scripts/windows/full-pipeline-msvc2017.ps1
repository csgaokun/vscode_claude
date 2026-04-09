param(
    [string]$QtRoot = 'C:\Qt\Qt5.12.12\5.12.12\msvc2017_64',
    [string]$SourceDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$BuildRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path '_build\msvc2017_64_qt5.12.12'),
    [ValidateSet('Release', 'Debug')][string]$BuildType = 'Release',
    [switch]$SkipBuild,
    [switch]$SkipPublish,
    [switch]$SkipSmokeTest,
    [switch]$EnableVerboseQtLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Keep policy change local to this process only.
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

. (Join-Path $PSScriptRoot 'common-env.ps1')

$logsDir = Join-Path $BuildRoot 'logs'
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$summaryLog = Join-Path $logsDir ("$runId-99-full-pipeline.log")

function Write-Summary {
    param([string]$Line)
    $Line | Tee-Object -FilePath $summaryLog -Append
}

Write-Summary "=== Qt Creator Full Pipeline ==="
Write-Summary "RunId: $runId"
Write-Summary "QtRoot: $QtRoot"
Write-Summary "BuildRoot: $BuildRoot"
Write-Summary "BuildType: $BuildType"
Write-Summary "SkipBuild: $SkipBuild"
Write-Summary "SkipPublish: $SkipPublish"
Write-Summary "SkipSmokeTest: $SkipSmokeTest"
Write-Summary ""

try {
    if (-not $SkipBuild) {
        Write-Summary "[1/3] Build start"
        & (Join-Path $PSScriptRoot 'build-qtcreator-msvc2017.ps1') `
            -QtRoot $QtRoot `
            -SourceDir $SourceDir `
            -BuildRoot $BuildRoot `
            -BuildType $BuildType
        if ($LASTEXITCODE -ne 0) {
            throw "Build step failed."
        }
        Write-Summary "[1/3] Build done"
    } else {
        Write-Summary "[1/3] Build skipped"
    }

    if (-not $SkipPublish) {
        Write-Summary "[2/3] Publish start"
        & (Join-Path $PSScriptRoot 'publish-qtcreator.ps1') `
            -QtRoot $QtRoot `
            -SourceDir $SourceDir `
            -BuildRoot $BuildRoot `
            -BuildType $BuildType
        if ($LASTEXITCODE -ne 0) {
            throw "Publish step failed."
        }
        Write-Summary "[2/3] Publish done"
    } else {
        Write-Summary "[2/3] Publish skipped"
    }

    if (-not $SkipSmokeTest) {
        Write-Summary "[3/3] Smoke test start"
        $debugArgs = @{
            QtRoot = $QtRoot
            BuildRoot = $BuildRoot
            Arguments = '--help'
        }
        if ($EnableVerboseQtLogs) {
            $debugArgs.EnableVerboseQtLogs = $true
        }

        & (Join-Path $PSScriptRoot 'debug-run-qtcreator.ps1') @debugArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Smoke test step failed."
        }
        Write-Summary "[3/3] Smoke test done"
    } else {
        Write-Summary "[3/3] Smoke test skipped"
    }

    $artifactZip = Join-Path $BuildRoot ('artifacts\qtcreator-msvc2017-qt5.12.12-' + $BuildType.ToLowerInvariant() + '.zip')
    if (Test-Path -LiteralPath $artifactZip) {
        Write-Summary "Artifact: $artifactZip"
    } else {
        Write-Summary "Artifact: NOT FOUND ($artifactZip)"
    }

    Write-Summary "SummaryLog: $summaryLog"
    Write-Summary "Pipeline completed successfully."
}
catch {
    Write-Summary ("Pipeline failed: " + $_.Exception.Message)
    Write-Summary "SummaryLog: $summaryLog"
    throw
}
