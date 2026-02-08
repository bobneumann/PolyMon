<#
.SYNOPSIS
    Installs or upgrades PolyMon on the target machine.

.DESCRIPTION
    Interactive installer that handles both fresh install and upgrade:
    - Detects existing PolyMonExecutive service for upgrade
    - Stops service, backs up existing files, copies new files
    - Updates connection strings in config files
    - Preserves ExecutiveID on upgrade
    - Creates/updates the PolyMon database
    - Installs the Windows service and starts it
    - Creates Start Menu shortcuts

    Requires elevation (Run as Administrator).

.PARAMETER SqlInstance
    SQL Server instance. Skips the prompt if provided.

.PARAMETER DatabaseName
    Database name. Default: PolyMon

.PARAMETER InstallDir
    Installation directory. Default: C:\Program Files\PolyMon

.PARAMETER NonInteractive
    Run without prompts (use defaults or parameters).

.EXAMPLE
    .\Install-PolyMon.ps1
    .\Install-PolyMon.ps1 -SqlInstance "MYPC\SQLEXPRESS" -NonInteractive
#>
[CmdletBinding()]
param(
    [string]$SqlInstance,
    [string]$DatabaseName,
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
# Globals & state tracking for rollback
# ============================================================
$PackageDir    = $PSScriptRoot
$CompletedSteps = [System.Collections.ArrayList]::new()
$BackupDir     = $null
$OldExecId     = $null
$ServiceWasRunning = $false

# ============================================================
# Helper functions
# ============================================================
function Write-Step  { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "   $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "   $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "   $Msg" -ForegroundColor Red }

function Prompt-Value {
    param([string]$Prompt, [string]$Default)
    if ($NonInteractive) { return $Default }
    $input_val = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($input_val)) { return $Default }
    return $input_val.Trim()
}

function Prompt-YesNo {
    param([string]$Prompt, [bool]$Default = $true)
    if ($NonInteractive) { return $Default }
    $hint = if ($Default) { 'Y/n' } else { 'y/N' }
    $input_val = Read-Host "$Prompt [$hint]"
    if ([string]::IsNullOrWhiteSpace($input_val)) { return $Default }
    return $input_val.Trim().ToUpper().StartsWith('Y')
}

# --- SQL execution ---
# Tries: 1) Invoke-Sqlcmd (SqlServer module), 2) sqlcmd.exe, 3) manual
$Script:SqlMethod = $null

function Find-SqlMethod {
    # Try Invoke-Sqlcmd
    if (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue) {
        $Script:SqlMethod = 'InvokeSqlcmd'
        Write-Ok 'SQL tool: Invoke-Sqlcmd (SqlServer module)'
        return
    }

    # Try importing SqlServer module
    try {
        Import-Module SqlServer -ErrorAction Stop
        if (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue) {
            $Script:SqlMethod = 'InvokeSqlcmd'
            Write-Ok 'SQL tool: Invoke-Sqlcmd (SqlServer module, just imported)'
            return
        }
    } catch {}

    # Try sqlcmd.exe
    if (Get-Command sqlcmd.exe -ErrorAction SilentlyContinue) {
        $Script:SqlMethod = 'Sqlcmd'
        Write-Ok 'SQL tool: sqlcmd.exe'
        return
    }

    # Check common paths for sqlcmd
    $sqlcmdPaths = @(
        "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn\sqlcmd.exe"
        "${env:ProgramFiles}\Microsoft SQL Server\*\Tools\Binn\sqlcmd.exe"
    )
    foreach ($pattern in $sqlcmdPaths) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $Script:SqlMethod = 'SqlcmdPath'
            $Script:SqlcmdExe = $found.FullName
            Write-Ok "SQL tool: $($found.FullName)"
            return
        }
    }

    $Script:SqlMethod = 'Manual'
    Write-Warn 'No SQL command-line tool found. SQL scripts will need to be run manually.'
}

function Invoke-SqlScript {
    param(
        [string]$ServerInstance,
        [string]$Database,
        [string]$ScriptPath,
        [string]$Description
    )
    Write-Host "   Running: $Description ..." -NoNewline

    switch ($Script:SqlMethod) {
        'InvokeSqlcmd' {
            $params = @{
                ServerInstance         = $ServerInstance
                Database               = $Database
                InputFile              = $ScriptPath
                QueryTimeout           = 300
                TrustServerCertificate = $true
                ErrorAction            = 'Stop'
            }
            Invoke-Sqlcmd @params
        }
        'Sqlcmd' {
            $result = sqlcmd.exe -S $ServerInstance -d $Database -i $ScriptPath -C -b 2>&1
            if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed: $result" }
        }
        'SqlcmdPath' {
            $result = & $Script:SqlcmdExe -S $ServerInstance -d $Database -i $ScriptPath -C -b 2>&1
            if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed: $result" }
        }
        'Manual' {
            Write-Host ''
            Write-Warn "MANUAL ACTION REQUIRED: Run this script in SSMS:"
            Write-Warn "  Server: $ServerInstance"
            Write-Warn "  Database: $Database"
            Write-Warn "  Script: $ScriptPath"
            Write-Host ''
            Read-Host '   Press Enter after you have run the script'
            return
        }
    }
    Write-Host ' Done.' -ForegroundColor Green
}

function Invoke-SqlQuery {
    param(
        [string]$ServerInstance,
        [string]$Database,
        [string]$Query
    )
    switch ($Script:SqlMethod) {
        'InvokeSqlcmd' {
            return Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database `
                -Query $Query -TrustServerCertificate -ErrorAction Stop
        }
        'Sqlcmd' {
            $result = sqlcmd.exe -S $ServerInstance -d $Database -Q $Query -C -h -1 -W 2>&1
            if ($LASTEXITCODE -ne 0) { throw "sqlcmd query failed: $result" }
            return $result
        }
        'SqlcmdPath' {
            $result = & $Script:SqlcmdExe -S $ServerInstance -d $Database -Q $Query -C -h -1 -W 2>&1
            if ($LASTEXITCODE -ne 0) { throw "sqlcmd query failed: $result" }
            return $result
        }
        'Manual' { return $null }
    }
}

function Test-DatabaseExists {
    param([string]$ServerInstance, [string]$Database)
    try {
        $query = "SELECT DB_ID('$Database')"
        $result = Invoke-SqlQuery -ServerInstance $ServerInstance -Database 'master' -Query $query
        if ($Script:SqlMethod -eq 'Manual') {
            return (Prompt-YesNo "Does database '$Database' already exist on $ServerInstance?")
        }
        # Invoke-Sqlcmd returns DataRow, sqlcmd returns string
        if ($result -is [System.Data.DataRow]) {
            return ($null -ne $result[0] -and $result[0] -isnot [DBNull])
        }
        $text = ($result | Out-String).Trim()
        return ($text -ne '' -and $text -ne 'NULL')
    }
    catch {
        Write-Warn "Could not check database existence: $_"
        return (Prompt-YesNo "Does database '$Database' already exist on $ServerInstance?")
    }
}

function Get-DbVersion {
    param([string]$ServerInstance, [string]$Database)
    try {
        $query = "SELECT TOP 1 Value FROM Settings WHERE Name = 'DBVersion'"
        $result = Invoke-SqlQuery -ServerInstance $ServerInstance -Database $Database -Query $query
        if ($Script:SqlMethod -eq 'Manual') { return $null }
        if ($result -is [System.Data.DataRow]) { return $result.Value }
        return ($result | Out-String).Trim()
    }
    catch {
        # Table might not exist or column missing — try alternate approach
        try {
            $query = "IF OBJECT_ID('Settings','U') IS NOT NULL SELECT TOP 1 Value FROM Settings WHERE Name = 'DBVersion'"
            $result = Invoke-SqlQuery -ServerInstance $ServerInstance -Database $Database -Query $query
            if ($result -is [System.Data.DataRow]) { return $result.Value }
            $text = ($result | Out-String).Trim()
            if ($text -and $text -ne '') { return $text }
        } catch {}
        return $null
    }
}

# --- Service management ---
function Get-PolyMonService {
    Get-Service -Name 'PolyMonExecutive' -ErrorAction SilentlyContinue
}

function Stop-PolyMonService {
    $svc = Get-PolyMonService
    if ($svc -and $svc.Status -ne 'Stopped') {
        Write-Host '   Stopping PolyMonExecutive service...' -NoNewline
        Stop-Service 'PolyMonExecutive' -Force -ErrorAction SilentlyContinue
        $svc.WaitForStatus('Stopped', (New-TimeSpan -Seconds 30))
        Write-Host ' Stopped.' -ForegroundColor Green
        return $true
    }
    return $false
}

function Find-InstallUtil {
    # Prefer 64-bit .NET 4 InstallUtil
    $candidates = @(
        (Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe')
        (Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

# --- Config file helpers ---
function Update-ConfigConnectionString {
    param([string]$ConfigPath, [string]$ConnectionString)
    if (-not (Test-Path $ConfigPath)) {
        Write-Warn "Config not found: $ConfigPath"
        return
    }
    $xml = [xml](Get-Content $ConfigPath -Raw)
    $node = $xml.configuration.appSettings.add | Where-Object { $_.key -eq 'SQLConn' }
    if ($node) {
        $node.value = $ConnectionString
        $xml.Save($ConfigPath)
    }
    else {
        Write-Warn "SQLConn key not found in $ConfigPath"
    }
}

function Get-ConfigValue {
    param([string]$ConfigPath, [string]$Key)
    if (-not (Test-Path $ConfigPath)) { return $null }
    $xml = [xml](Get-Content $ConfigPath -Raw)
    $node = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $Key }
    if ($node) { return $node.value }
    return $null
}

function Set-ConfigValue {
    param([string]$ConfigPath, [string]$Key, [string]$Value)
    if (-not (Test-Path $ConfigPath)) { return }
    $xml = [xml](Get-Content $ConfigPath -Raw)
    $node = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $Key }
    if ($node) {
        $node.value = $Value
        $xml.Save($ConfigPath)
    }
}

function Get-ConnectionStringFromConfig {
    param([string]$ConfigPath)
    return Get-ConfigValue -ConfigPath $ConfigPath -Key 'SQLConn'
}

function Parse-SqlInstanceFromConnString {
    param([string]$ConnStr)
    if ($ConnStr -match 'Data Source\s*=\s*([^;]+)') {
        return $Matches[1].Trim()
    }
    return $null
}

function Parse-DatabaseFromConnString {
    param([string]$ConnStr)
    if ($ConnStr -match 'Initial Catalog\s*=\s*([^;]+)') {
        return $Matches[1].Trim()
    }
    return $null
}

# ============================================================
# Rollback
# ============================================================
function Invoke-Rollback {
    param([string]$Reason)
    Write-Host ''
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' -ForegroundColor Red
    Write-Err "INSTALLATION FAILED: $Reason"
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Rolling back completed steps...' -ForegroundColor Yellow

    # Reverse order
    $steps = $CompletedSteps.ToArray()
    [array]::Reverse($steps)

    foreach ($step in $steps) {
        try {
            switch ($step) {
                'ServiceStarted' {
                    Write-Host '   Rolling back: Stopping service...'
                    Stop-Service 'PolyMonExecutive' -Force -ErrorAction SilentlyContinue
                }
                'ServiceInstalled' {
                    Write-Host '   Rolling back: Uninstalling service...'
                    $installUtil = Find-InstallUtil
                    $exePath = Join-Path $InstallDir 'PolyMon Executive\PolyMonExecutive.exe'
                    if ($installUtil -and (Test-Path $exePath)) {
                        & $installUtil /u $exePath 2>&1 | Out-Null
                    }
                }
                'FilesCopied' {
                    if ($BackupDir -and (Test-Path $BackupDir)) {
                        Write-Host '   Rolling back: Restoring files from backup...'
                        # Remove new files
                        $mgrDir = Join-Path $InstallDir 'PolyMon Manager'
                        $execDir = Join-Path $InstallDir 'PolyMon Executive'
                        if (Test-Path $mgrDir)  { Remove-Item $mgrDir -Recurse -Force -ErrorAction SilentlyContinue }
                        if (Test-Path $execDir) { Remove-Item $execDir -Recurse -Force -ErrorAction SilentlyContinue }

                        # Restore backup
                        Get-ChildItem $BackupDir | ForEach-Object {
                            Copy-Item $_.FullName -Destination $InstallDir -Recurse -Force
                        }
                    }
                    elseif (-not $IsUpgrade) {
                        Write-Host '   Rolling back: Removing installed files...'
                        if (Test-Path $InstallDir) {
                            Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                'OldServiceUninstalled' {
                    if ($BackupDir -and (Test-Path $BackupDir)) {
                        Write-Host '   Rolling back: Re-installing old service...'
                        $oldExe = Join-Path $BackupDir 'PolyMon Executive\PolyMonExecutive.exe'
                        $installUtil = Find-InstallUtil
                        if ($installUtil -and (Test-Path $oldExe)) {
                            & $installUtil $oldExe 2>&1 | Out-Null
                        }
                        if ($ServiceWasRunning) {
                            Start-Service 'PolyMonExecutive' -ErrorAction SilentlyContinue
                        }
                    }
                }
                'Shortcuts' {
                    Write-Host '   Rolling back: Removing shortcuts...'
                    $smDir = Join-Path ([Environment]::GetFolderPath('CommonPrograms')) 'PolyMon'
                    if (Test-Path $smDir) {
                        Remove-Item $smDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        catch {
            Write-Warn "   Rollback step '$step' failed: $_"
        }
    }

    Write-Host ''
    Write-Err 'Rollback complete. Please check the system state.'
    if ($BackupDir -and (Test-Path $BackupDir)) {
        Write-Warn "Backup preserved at: $BackupDir"
    }
    exit 1
}

# ============================================================
# MAIN
# ============================================================
Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '       PolyMon Installer v1.0'           -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# --- Verify package contents ---
Write-Step 'Verifying package contents'

$requiredDirs = @(
    (Join-Path $PackageDir 'PolyMon Manager')
    (Join-Path $PackageDir 'PolyMon Executive')
    (Join-Path $PackageDir 'SQL')
)
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        Write-Err "Package directory missing: $dir"
        Write-Err 'Run Build-PolyMonPackage.ps1 first to create the install package.'
        exit 1
    }
}
Write-Ok 'Package contents verified.'

# --- Detect existing installation ---
Write-Step 'Detecting existing installation'

$IsUpgrade = $false
$ExistingSqlInstance = $null
$ExistingDbName = $null
$ExistingInstallDir = $null

$existingSvc = Get-PolyMonService
if ($existingSvc) {
    Write-Ok 'Found existing PolyMonExecutive service.'
    $IsUpgrade = $true

    # Try to find the existing install path from service binary path
    try {
        $svcWmi = Get-CimInstance Win32_Service -Filter "Name='PolyMonExecutive'" -ErrorAction Stop
        $svcPath = $svcWmi.PathName -replace '"', ''
        if ($svcPath -and (Test-Path $svcPath)) {
            # Service exe is in "<InstallDir>\PolyMon Executive\PolyMonExecutive.exe"
            $execDir = Split-Path $svcPath -Parent
            $ExistingInstallDir = Split-Path $execDir -Parent

            # Read existing config
            $existingConfig = Join-Path $execDir 'PolyMonExecutive.exe.config'
            if (Test-Path $existingConfig) {
                $connStr = Get-ConnectionStringFromConfig -ConfigPath $existingConfig
                if ($connStr) {
                    $ExistingSqlInstance = Parse-SqlInstanceFromConnString -ConnStr $connStr
                    $ExistingDbName = Parse-DatabaseFromConnString -ConnStr $connStr
                }
                $OldExecId = Get-ConfigValue -ConfigPath $existingConfig -Key 'ExecutiveID'
                Write-Ok "Existing SQL instance: $ExistingSqlInstance"
                Write-Ok "Existing database: $ExistingDbName"
                Write-Ok "Existing ExecutiveID: $OldExecId"
                Write-Ok "Existing install dir: $ExistingInstallDir"
            }
        }
    }
    catch {
        Write-Warn "Could not read existing service config: $_"
    }
}
else {
    Write-Ok 'No existing installation detected. Fresh install.'
}

# --- Prompt for settings ---
Write-Step 'Installation settings'

$defaultSqlInstance = if ($ExistingSqlInstance) { $ExistingSqlInstance } else { '.\SQLEXPRESS' }
$defaultDbName      = if ($ExistingDbName) { $ExistingDbName } else { 'PolyMon' }
$defaultInstallDir  = if ($ExistingInstallDir) { $ExistingInstallDir } else { 'C:\Program Files\PolyMon' }

if (-not $SqlInstance)   { $SqlInstance   = Prompt-Value 'SQL Server instance'  $defaultSqlInstance }
if (-not $DatabaseName)  { $DatabaseName  = Prompt-Value 'Database name'        $defaultDbName }
if (-not $InstallDir)    { $InstallDir    = Prompt-Value 'Install directory'    $defaultInstallDir }

$ConnectionString = "Data Source=$SqlInstance;Initial Catalog=$DatabaseName; Integrated Security=SSPI;"

Write-Host ''
Write-Host '   Installation Summary:' -ForegroundColor White
Write-Host "   Mode:           $(if ($IsUpgrade) { 'UPGRADE' } else { 'Fresh Install' })"
Write-Host "   SQL Instance:   $SqlInstance"
Write-Host "   Database:       $DatabaseName"
Write-Host "   Install Dir:    $InstallDir"
Write-Host "   Connection:     $ConnectionString"
Write-Host ''

if ($IsUpgrade -and -not $NonInteractive) {
    Write-Warn 'UPGRADE MODE: Existing files will be backed up before overwriting.'
    Write-Warn 'Make sure you have a recent database backup!'
    if (-not (Prompt-YesNo 'Continue with upgrade?')) {
        Write-Host 'Installation cancelled.' -ForegroundColor Yellow
        exit 0
    }
}
elseif (-not $NonInteractive) {
    if (-not (Prompt-YesNo 'Continue with installation?')) {
        Write-Host 'Installation cancelled.' -ForegroundColor Yellow
        exit 0
    }
}

# --- Find SQL tool ---
Write-Step 'Checking SQL tools'
Find-SqlMethod

# --- Find InstallUtil ---
Write-Step 'Checking .NET tools'
$InstallUtil = Find-InstallUtil
if ($InstallUtil) {
    Write-Ok "InstallUtil: $InstallUtil"
}
else {
    Write-Err 'InstallUtil.exe not found. .NET Framework 4.x must be installed.'
    exit 1
}

# ============================================================
# Step 1: Stop existing service
# ============================================================
if ($IsUpgrade) {
    Write-Step 'Step 1: Stopping existing service'
    $ServiceWasRunning = Stop-PolyMonService
    if ($ServiceWasRunning) {
        Write-Ok 'Service stopped.'
    }
    else {
        Write-Ok 'Service was already stopped.'
    }
}

# ============================================================
# Step 2: Back up existing files
# ============================================================
if ($IsUpgrade -and (Test-Path $InstallDir)) {
    Write-Step 'Step 2: Backing up existing installation'
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $BackupDir = Join-Path (Split-Path $InstallDir -Parent) "_backup_PolyMon_$timestamp"
    Write-Host "   Backup location: $BackupDir"

    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Get-ChildItem $InstallDir | ForEach-Object {
        Copy-Item $_.FullName -Destination $BackupDir -Recurse -Force
    }

    $backupCount = (Get-ChildItem $BackupDir -Recurse -File).Count
    Write-Ok "Backed up $backupCount files."
    $CompletedSteps.Add('BackedUp') | Out-Null
}

# ============================================================
# Step 3: Uninstall old service
# ============================================================
if ($IsUpgrade) {
    Write-Step 'Step 3: Uninstalling old service'
    $oldExe = Join-Path $InstallDir 'PolyMon Executive\PolyMonExecutive.exe'
    if (Test-Path $oldExe) {
        try {
            $output = & $InstallUtil /u $oldExe 2>&1
            Write-Ok 'Old service uninstalled.'
        }
        catch {
            Write-Warn "Service uninstall warning: $_"
        }
    }
    else {
        Write-Warn 'Old service executable not found, skipping uninstall.'
    }
    $CompletedSteps.Add('OldServiceUninstalled') | Out-Null
}

# ============================================================
# Step 4: Create directories and copy files
# ============================================================
Write-Step "Step $(if ($IsUpgrade) {'4'} else {'1'}): Copying files"

$mgrDest  = Join-Path $InstallDir 'PolyMon Manager'
$monDest  = Join-Path $InstallDir 'PolyMon Manager\Monitors'
$execDest = Join-Path $InstallDir 'PolyMon Executive'

foreach ($dir in @($mgrDest, $monDest, $execDest)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

try {
    # Manager
    $srcManager = Join-Path $PackageDir 'PolyMon Manager'
    Get-ChildItem $srcManager -File | ForEach-Object {
        Copy-Item $_.FullName -Destination $mgrDest -Force
    }

    # Monitors
    $srcMonitors = Join-Path $PackageDir 'PolyMon Manager\Monitors'
    if (Test-Path $srcMonitors) {
        Get-ChildItem $srcMonitors -File | ForEach-Object {
            Copy-Item $_.FullName -Destination $monDest -Force
        }
    }

    # Executive
    $srcExec = Join-Path $PackageDir 'PolyMon Executive'
    Get-ChildItem $srcExec -File | ForEach-Object {
        Copy-Item $_.FullName -Destination $execDest -Force
    }

    $totalFiles = (Get-ChildItem $InstallDir -Recurse -File).Count
    Write-Ok "Copied $totalFiles files."
    $CompletedSteps.Add('FilesCopied') | Out-Null
}
catch {
    Invoke-Rollback "File copy failed: $_"
}

# ============================================================
# Step 5: Update connection strings
# ============================================================
Write-Step "Updating connection strings"

try {
    $mgrConfig  = Join-Path $mgrDest  'PolyMonManager.exe.config'
    $execConfig = Join-Path $execDest 'PolyMonExecutive.exe.config'

    Update-ConfigConnectionString -ConfigPath $mgrConfig  -ConnectionString $ConnectionString
    Update-ConfigConnectionString -ConfigPath $execConfig -ConnectionString $ConnectionString

    Write-Ok "Manager config: $mgrConfig"
    Write-Ok "Executive config: $execConfig"
}
catch {
    Invoke-Rollback "Config update failed: $_"
}

# ============================================================
# Step 6: Preserve ExecutiveID (upgrade)
# ============================================================
if ($IsUpgrade -and $OldExecId) {
    Write-Step 'Preserving ExecutiveID'
    $execConfig = Join-Path $execDest 'PolyMonExecutive.exe.config'
    Set-ConfigValue -ConfigPath $execConfig -Key 'ExecutiveID' -Value $OldExecId
    Write-Ok "ExecutiveID preserved: $OldExecId"
}

# ============================================================
# Step 7: Database setup
# ============================================================
Write-Step 'Database setup'

if ($Script:SqlMethod -ne 'Manual') {
    $dbExists = Test-DatabaseExists -ServerInstance $SqlInstance -Database $DatabaseName

    if (-not $dbExists) {
        Write-Host '   Database does not exist. Creating...'

        # Create the database
        try {
            $createDbQuery = "CREATE DATABASE [$DatabaseName]"
            Invoke-SqlQuery -ServerInstance $SqlInstance -Database 'master' -Query $createDbQuery
            Write-Ok "Database '$DatabaseName' created."
        }
        catch {
            Invoke-Rollback "Database creation failed: $_"
        }

        # Run full creation script
        $createScript = Join-Path $PackageDir 'SQL\DB Version 1.30.sql'
        if (Test-Path $createScript) {
            try {
                Invoke-SqlScript -ServerInstance $SqlInstance -Database $DatabaseName `
                    -ScriptPath $createScript -Description 'DB Version 1.30 (full creation)'
            }
            catch {
                Invoke-Rollback "Database creation script failed: $_"
            }
        }
        else {
            Write-Warn 'DB Version 1.30.sql not found in package. Database tables not created.'
        }
    }
    else {
        Write-Ok "Database '$DatabaseName' already exists."

        # Check version and run update scripts if needed
        $dbVersion = Get-DbVersion -ServerInstance $SqlInstance -Database $DatabaseName
        Write-Host "   Current DB version: $(if ($dbVersion) { $dbVersion } else { 'unknown' })"

        if ($dbVersion) {
            $updateScripts = @()

            switch ($dbVersion) {
                '1.00' {
                    $updateScripts += @{ Path = (Join-Path $PackageDir 'SQL\Update DB 1.00 to 1.10.sql'); Desc = 'Update 1.00 -> 1.10' }
                    $updateScripts += @{ Path = (Join-Path $PackageDir 'SQL\Update DB 1.10 to 1.30.sql'); Desc = 'Update 1.10 -> 1.30' }
                }
                '1.10' {
                    $updateScripts += @{ Path = (Join-Path $PackageDir 'SQL\Update DB 1.10 to 1.30.sql'); Desc = 'Update 1.10 -> 1.30' }
                }
                '1.30' {
                    Write-Ok 'Database is already at version 1.30. No updates needed.'
                }
                default {
                    Write-Warn "Unknown DB version '$dbVersion'. Skipping update scripts."
                    Write-Warn 'You may need to run update scripts manually.'
                }
            }

            foreach ($us in $updateScripts) {
                if (Test-Path $us.Path) {
                    try {
                        Invoke-SqlScript -ServerInstance $SqlInstance -Database $DatabaseName `
                            -ScriptPath $us.Path -Description $us.Desc
                    }
                    catch {
                        Write-Warn "Update script failed: $($us.Desc) - $_"
                        Write-Warn 'Continuing installation. You may need to run this manually.'
                    }
                }
                else {
                    Write-Warn "Update script not found: $($us.Path)"
                }
            }
        }
        else {
            Write-Warn 'Could not determine DB version. Skipping update scripts.'
            Write-Warn 'Check the Settings table and run update scripts manually if needed.'
        }
    }

    # Always extend TS tables
    $tsScript = Join-Path $PackageDir 'SQL\TSData-Extend.sql'
    if (Test-Path $tsScript) {
        try {
            Invoke-SqlScript -ServerInstance $SqlInstance -Database $DatabaseName `
                -ScriptPath $tsScript -Description 'Extend TS tables through 2035'
        }
        catch {
            Write-Warn "TS extension failed: $_"
            Write-Warn 'You can run TSData-Extend.sql manually later.'
        }
    }
}
else {
    Write-Warn 'No SQL tool available. Manual database setup required:'
    Write-Warn "  1. Connect to $SqlInstance in SSMS"
    if (-not (Prompt-YesNo "Does database '$DatabaseName' already exist?" $true)) {
        Write-Warn "  2. Create database: CREATE DATABASE [$DatabaseName]"
        Write-Warn "  3. Run: $(Join-Path $PackageDir 'SQL\DB Version 1.30.sql')"
    }
    else {
        Write-Warn '  2. Check the DB version in the Settings table'
        Write-Warn "  3. Run any needed update scripts from: $(Join-Path $PackageDir 'SQL')"
    }
    Write-Warn "  4. Run: $(Join-Path $PackageDir 'SQL\TSData-Extend.sql')"
    Write-Host ''
    Read-Host '   Press Enter to continue after completing database setup'
}

# ============================================================
# Step 8: Install service
# ============================================================
Write-Step 'Installing PolyMonExecutive service'

$execExe = Join-Path $execDest 'PolyMonExecutive.exe'
if (-not (Test-Path $execExe)) {
    Invoke-Rollback "Service executable not found: $execExe"
}

try {
    $output = & $InstallUtil $execExe 2>&1
    # Check if service was registered
    Start-Sleep -Seconds 2
    $svc = Get-PolyMonService
    if ($svc) {
        Write-Ok 'Service installed successfully.'
        $CompletedSteps.Add('ServiceInstalled') | Out-Null
    }
    else {
        # InstallUtil may have succeeded but service name might differ
        Write-Warn 'Service may not have installed correctly. Check services.msc.'
        Write-Warn "InstallUtil output: $($output | Out-String)"
        $CompletedSteps.Add('ServiceInstalled') | Out-Null
    }
}
catch {
    Invoke-Rollback "Service installation failed: $_"
}

# ============================================================
# Step 9: Start service
# ============================================================
Write-Step 'Starting PolyMonExecutive service'

try {
    Start-Service 'PolyMonExecutive' -ErrorAction Stop
    Start-Sleep -Seconds 3
    $svc = Get-PolyMonService
    if ($svc.Status -eq 'Running') {
        Write-Ok 'Service is running.'
        $CompletedSteps.Add('ServiceStarted') | Out-Null
    }
    else {
        Write-Warn "Service status: $($svc.Status)"
        Write-Warn 'Check Event Viewer > Application log for errors.'
    }
}
catch {
    Write-Warn "Could not start service: $_"
    Write-Warn 'The service may need to be configured (Log On account) before starting.'
    Write-Warn 'Check Event Viewer > Application log for details.'
}

# ============================================================
# Step 10: Start Menu shortcuts
# ============================================================
Write-Step 'Creating Start Menu shortcuts'

try {
    $smDir = Join-Path ([Environment]::GetFolderPath('CommonPrograms')) 'PolyMon'
    if (-not (Test-Path $smDir)) {
        New-Item -ItemType Directory -Path $smDir -Force | Out-Null
    }

    $WshShell = New-Object -ComObject WScript.Shell

    # Manager shortcut
    $mgrExe = Join-Path $mgrDest 'PolyMonManager.exe'
    if (Test-Path $mgrExe) {
        $shortcut = $WshShell.CreateShortcut((Join-Path $smDir 'PolyMon Manager.lnk'))
        $shortcut.TargetPath = $mgrExe
        $shortcut.WorkingDirectory = $mgrDest
        $shortcut.Description = 'PolyMon Manager'
        $shortcut.Save()
        Write-Ok 'Created: PolyMon Manager shortcut'
    }

    $CompletedSteps.Add('Shortcuts') | Out-Null
}
catch {
    Write-Warn "Shortcut creation failed: $_"
    Write-Warn 'You can create shortcuts manually.'
}

# ============================================================
# Step 11: Verification
# ============================================================
Write-Step 'Verification'

$issues = @()

# Check service
$svc = Get-PolyMonService
if ($svc -and $svc.Status -eq 'Running') {
    Write-Ok 'Service: Running'
}
elseif ($svc) {
    Write-Warn "Service: $($svc.Status)"
    $issues += 'Service is not running'
}
else {
    Write-Err 'Service: Not found'
    $issues += 'Service not found'
}

# Check Manager exe
$mgrExe = Join-Path $mgrDest 'PolyMonManager.exe'
if (Test-Path $mgrExe) {
    Write-Ok "Manager: $mgrExe"
}
else {
    Write-Err 'Manager: executable not found'
    $issues += 'Manager executable missing'
}

# Check Executive config connection string
$execConfig = Join-Path $execDest 'PolyMonExecutive.exe.config'
if (Test-Path $execConfig) {
    $cfgConn = Get-ConnectionStringFromConfig -ConfigPath $execConfig
    if ($cfgConn -and $cfgConn.Contains($SqlInstance)) {
        Write-Ok "Executive config: connection string updated"
    }
    else {
        Write-Warn "Executive config: connection string may not be correct"
        $issues += 'Connection string mismatch'
    }
}

# Check for Ascend DLLs
$ascendMissing = @()
foreach ($dll in @('Ascend.dll', 'Ascend.Design.dll', 'Ascend.Resources.dll', 'Ascend.Windows.Forms.dll')) {
    if (-not (Test-Path (Join-Path $mgrDest $dll))) {
        $ascendMissing += $dll
    }
}
if ($ascendMissing.Count -gt 0) {
    Write-Warn "Ascend DLLs not present (Manager ran fine without them on dev machine):"
    $ascendMissing | ForEach-Object { Write-Warn "  - $_" }
    Write-Warn "If Manager crashes at work, check if these DLLs exist on the old installation."
}

# Check database connectivity
if ($Script:SqlMethod -ne 'Manual') {
    try {
        $result = Invoke-SqlQuery -ServerInstance $SqlInstance -Database $DatabaseName `
            -Query "SELECT COUNT(*) AS Cnt FROM Monitor"
        Write-Ok "Database: connected, monitors found"
    }
    catch {
        Write-Warn "Database connectivity check failed: $_"
        $issues += 'Database connectivity'
    }
}

# --- Summary ---
Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host '   Installation completed successfully!' -ForegroundColor Green
}
else {
    Write-Host '   Installation completed with warnings:' -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Warn "   - $issue"
    }
}
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "   Install directory: $InstallDir" -ForegroundColor White
Write-Host "   Manager:          $mgrExe" -ForegroundColor White
Write-Host "   SQL Instance:     $SqlInstance" -ForegroundColor White
Write-Host "   Database:         $DatabaseName" -ForegroundColor White
if ($BackupDir -and (Test-Path $BackupDir)) {
    Write-Host "   Backup:           $BackupDir" -ForegroundColor White
}
Write-Host ''
Write-Host '   Next steps:' -ForegroundColor White
Write-Host '   1. Launch PolyMon Manager from the Start Menu' -ForegroundColor White
Write-Host '   2. Verify monitors are listed and data is flowing' -ForegroundColor White
Write-Host '   3. Check Event Viewer > Application for any errors' -ForegroundColor White
Write-Host ''
