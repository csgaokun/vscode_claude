Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "`n==== $Message ====" -ForegroundColor Cyan
}

function Assert-FileExists {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file not found: $Path"
    }
}

function Assert-DirectoryExists {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Required directory not found: $Path"
    }
}

function Import-BatchEnvironment {
    param(
        [Parameter(Mandatory = $true)][string]$BatchFile,
        [string]$Arguments = ''
    )

    Assert-FileExists -Path $BatchFile

    $escapedBatch = $BatchFile.Replace('"', '""')
    $command = if ([string]::IsNullOrWhiteSpace($Arguments)) {
        "`"$escapedBatch`""
    } else {
        "`"$escapedBatch`" $Arguments"
    }

    $envDump = & cmd.exe /d /c "$command && set"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to import environment from batch file: $BatchFile"
    }

    foreach ($line in $envDump) {
        if ($line -match '^(.*?)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}

function Import-Vs2017Environment {
    $vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
    Assert-FileExists -Path $vswhere

    $installPath = & $vswhere -latest -products * -version '[15.0,16.0)' -property installationPath
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($installPath)) {
        throw 'Visual Studio 2017 not found. Please install VS2017 Build Tools or Visual Studio 2017.'
    }

    $vsDevCmd = Join-Path $installPath 'Common7\Tools\VsDevCmd.bat'
    Import-BatchEnvironment -BatchFile $vsDevCmd -Arguments '-arch=amd64 -host_arch=amd64'
}

function Import-QtEnvironment {
    param([Parameter(Mandatory = $true)][string]$QtRoot)

    Assert-DirectoryExists -Path $QtRoot

    $qtenv = Join-Path $QtRoot 'bin\qtenv2.bat'
    Import-BatchEnvironment -BatchFile $qtenv
}

function Ensure-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found in PATH: $Name"
    }
}

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$StepName
    )

    Write-Step -Message $StepName
    Write-Host "Command: $Command"

    $logDir = Split-Path -Parent $LogPath
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    "### $StepName" | Out-File -FilePath $LogPath -Encoding utf8
    "### $(Get-Date -Format o)" | Out-File -FilePath $LogPath -Encoding utf8 -Append
    "### Command: $Command" | Out-File -FilePath $LogPath -Encoding utf8 -Append
    "" | Out-File -FilePath $LogPath -Encoding utf8 -Append

    # Avoid PowerShell treating native stderr text as terminating errors.
    # Let cmd handle redirection, then use process exit code as the source of truth.
    $cmdWithRedirect = "$Command >> `"$LogPath`" 2>&1"
    & cmd.exe /d /c $cmdWithRedirect
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$StepName failed with exit code $exitCode. See log: $LogPath"
    }
}
