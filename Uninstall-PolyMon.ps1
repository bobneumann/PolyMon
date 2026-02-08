<#
.SYNOPSIS
    Uninstalls PolyMon from the target machine.

.DESCRIPTION
    Reverses the steps performed by Install-PolyMon.ps1:
    - Stops the PolyMonExecutive Windows service
    - Uninstalls the service via InstallUtil
    - Removes installed files (PolyMon Manager and PolyMon Executive)
    - Removes Start Menu shortcuts
    - Optionally removes the install directory

    Does NOT drop the PolyMon database (too dangerous to automate).

    Requires elevation (Run as Administrator).

.PARAMETER InstallDir
    Installation directory. Auto-detected from the service binary path
    if not specified. Default fallback: C:\Program Files\PolyMon

.PARAMETER NonInteractive
    Run without prompts. Removes files without asking, but does NOT
    remove the install directory itself unless it is empty.

.EXAMPLE
    .\Uninstall-PolyMon.ps1
    .\Uninstall-PolyMon.ps1 -InstallDir "C:\Program Files\PolyMon" -NonInteractive
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================
# Require elevation
# ============================================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: This script must be run as Administrator.' -ForegroundColor Red
    Write-Host 'Right-click PowerShell and select "Run as Administrator".' -ForegroundColor Yellow
    exit 1
}

# ============================================================
# Helper functions
# ============================================================
function Write-Step  { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "   $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "   $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "   $Msg" -ForegroundColor Red }

function Prompt-YesNo {
    param([string]$Prompt, [bool]$Default = $true)
    if ($NonInteractive) { return $Default }
    $hint = if ($Default) { 'Y/n' } else { 'y/N' }
    $input_val = Read-Host "$Prompt [$hint]"
    if ([string]::IsNullOrWhiteSpace($input_val)) { return $Default }
    return $input_val.Trim().ToUpper().StartsWith('Y')
}

function Get-PolyMonService {
    Get-Service -Name 'PolyMonExecutive' -ErrorAction SilentlyContinue
}

function Find-InstallUtil {
    $candidates = @(
        (Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe')
        (Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

# ============================================================
# MAIN
# ============================================================
Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '       PolyMon Uninstaller v1.0'         -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# ============================================================
# Detect existing installation
# ============================================================
Write-Step 'Detecting existing installation'

$DetectedInstallDir = $null
$ServiceExists = $false

$existingSvc = Get-PolyMonService
if ($existingSvc) {
    Write-Ok 'Found PolyMonExecutive service.'
    $ServiceExists = $true

    # Try to find the existing install path from service binary path
    try {
        $svcWmi = Get-CimInstance Win32_Service -Filter "Name='PolyMonExecutive'" -ErrorAction Stop
        $svcPath = $svcWmi.PathName -replace '"', ''
        if ($svcPath -and (Test-Path $svcPath)) {
            # Service exe is in "<InstallDir>\PolyMon Executive\PolyMonExecutive.exe"
            $execDir = Split-Path $svcPath -Parent
            $DetectedInstallDir = Split-Path $execDir -Parent
            Write-Ok "Detected install directory: $DetectedInstallDir"
        }
    }
    catch {
        Write-Warn "Could not read service binary path: $_"
    }
}
else {
    Write-Warn 'PolyMonExecutive service not found.'
}

# Resolve install directory
if (-not $InstallDir) {
    if ($DetectedInstallDir) {
        $InstallDir = $DetectedInstallDir
    }
    else {
        $InstallDir = 'C:\Program Files\PolyMon'
    }
}

if (-not (Test-Path $InstallDir) -and -not $ServiceExists) {
    Write-Err "Nothing to uninstall."
    Write-Err "Install directory does not exist: $InstallDir"
    Write-Err 'PolyMonExecutive service not found.'
    exit 1
}

# ============================================================
# Confirm uninstall
# ============================================================
Write-Host ''
Write-Host '   Uninstall Summary:' -ForegroundColor White
Write-Host "   Install Dir:    $InstallDir"
Write-Host "   Service:        $(if ($ServiceExists) { 'Found' } else { 'Not found' })"
Write-Host ''

if (-not (Prompt-YesNo 'Proceed with uninstall?')) {
    Write-Host 'Uninstall cancelled.' -ForegroundColor Yellow
    exit 0
}

# ============================================================
# Step 1: Stop the service
# ============================================================
Write-Step 'Step 1: Stopping PolyMonExecutive service'

if ($ServiceExists) {
    $svc = Get-PolyMonService
    if ($svc.Status -ne 'Stopped') {
        try {
            Write-Host '   Stopping service...' -NoNewline
            Stop-Service 'PolyMonExecutive' -Force -ErrorAction Stop
            $svc.WaitForStatus('Stopped', (New-TimeSpan -Seconds 30))
            Write-Host ' Stopped.' -ForegroundColor Green
        }
        catch {
            Write-Warn "Could not stop service gracefully: $_"
            Write-Warn 'Continuing with uninstall...'
        }
    }
    else {
        Write-Ok 'Service is already stopped.'
    }
}
else {
    Write-Ok 'Service not found, skipping.'
}

# ============================================================
# Step 2: Uninstall the service
# ============================================================
Write-Step 'Step 2: Uninstalling PolyMonExecutive service'

if ($ServiceExists) {
    $InstallUtil = Find-InstallUtil
    if ($InstallUtil) {
        Write-Ok "InstallUtil: $InstallUtil"

        $execExe = Join-Path $InstallDir 'PolyMon Executive\PolyMonExecutive.exe'
        if (Test-Path $execExe) {
            try {
                $output = & $InstallUtil /u $execExe 2>&1
                Write-Ok 'Service uninstalled.'
            }
            catch {
                Write-Warn "InstallUtil uninstall failed: $_"
                Write-Warn 'Attempting removal via sc.exe...'
                $scResult = sc.exe delete PolyMonExecutive 2>&1
                Write-Ok "sc.exe result: $scResult"
            }
        }
        else {
            Write-Warn "Service executable not found at: $execExe"
            Write-Warn 'Attempting removal via sc.exe...'
            $scResult = sc.exe delete PolyMonExecutive 2>&1
            Write-Ok "sc.exe result: $scResult"
        }
    }
    else {
        Write-Warn 'InstallUtil.exe not found. Attempting removal via sc.exe...'
        $scResult = sc.exe delete PolyMonExecutive 2>&1
        Write-Ok "sc.exe result: $scResult"
    }
}
else {
    Write-Ok 'Service not found, skipping.'
}

# ============================================================
# Step 3: Remove installed files
# ============================================================
Write-Step 'Step 3: Removing installed files'

$mgrDir  = Join-Path $InstallDir 'PolyMon Manager'
$execDir = Join-Path $InstallDir 'PolyMon Executive'
$removedFiles = 0

if (Test-Path $mgrDir) {
    $count = (Get-ChildItem $mgrDir -Recurse -File -ErrorAction SilentlyContinue).Count
    Remove-Item $mgrDir -Recurse -Force
    $removedFiles += $count
    Write-Ok "Removed: PolyMon Manager ($count files)"
}
else {
    Write-Warn "Not found: $mgrDir"
}

if (Test-Path $execDir) {
    $count = (Get-ChildItem $execDir -Recurse -File -ErrorAction SilentlyContinue).Count
    Remove-Item $execDir -Recurse -Force
    $removedFiles += $count
    Write-Ok "Removed: PolyMon Executive ($count files)"
}
else {
    Write-Warn "Not found: $execDir"
}

if ($removedFiles -gt 0) {
    Write-Ok "Total files removed: $removedFiles"
}

# ============================================================
# Step 4: Remove Start Menu shortcuts
# ============================================================
Write-Step 'Step 4: Removing Start Menu shortcuts'

$smDir = Join-Path ([Environment]::GetFolderPath('CommonPrograms')) 'PolyMon'
if (Test-Path $smDir) {
    Remove-Item $smDir -Recurse -Force
    Write-Ok 'Removed Start Menu shortcuts.'
}
else {
    Write-Ok 'No Start Menu shortcuts found.'
}

# ============================================================
# Step 5: Remove install directory (prompt)
# ============================================================
Write-Step 'Step 5: Install directory cleanup'

if (Test-Path $InstallDir) {
    $remaining = Get-ChildItem $InstallDir -Recurse -File -ErrorAction SilentlyContinue
    if ($remaining -and $remaining.Count -gt 0) {
        Write-Warn "Install directory still contains $($remaining.Count) file(s):"
        $remaining | Select-Object -First 10 | ForEach-Object {
            $rel = $_.FullName.Substring($InstallDir.Length + 1)
            Write-Warn "  $rel"
        }
        if ($remaining.Count -gt 10) {
            Write-Warn "  ... and $($remaining.Count - 10) more"
        }

        if (Prompt-YesNo 'Remove the install directory and all remaining files?' $false) {
            Remove-Item $InstallDir -Recurse -Force
            Write-Ok "Removed: $InstallDir"
        }
        else {
            Write-Ok "Kept: $InstallDir"
        }
    }
    else {
        # Directory is empty (or only has empty subdirectories)
        Remove-Item $InstallDir -Recurse -Force
        Write-Ok "Removed empty install directory: $InstallDir"
    }
}
else {
    Write-Ok 'Install directory already removed.'
}

# ============================================================
# Database notice
# ============================================================
Write-Step 'Database'

Write-Warn 'The PolyMon database has NOT been removed.'
Write-Warn 'If you want to remove it, use SQL Server Management Studio:'
Write-Warn '  DROP DATABASE [PolyMon]'
Write-Warn 'Make sure you have a backup first!'

# ============================================================
# Summary
# ============================================================
Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '   PolyMon uninstall complete.'           -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
