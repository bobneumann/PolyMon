# Matrix/Signal Bridge Health Monitor
# PolyMon PowerShell Monitor — paste into a new PowerShell monitor definition
# Checks: server alive, disk usage, container status, backup freshness

$BaseUrl = "https://matrix.thebuildist.com"

# Check 1: Is the Matrix server responding?
try {
    $versions = Invoke-RestMethod -Uri "$BaseUrl/_matrix/client/versions" -TimeoutSec 15
    if (-not $versions.versions) {
        throw "Unexpected response from Matrix server"
    }
} catch {
    $PolyMon.SetStatus([PolyMon.MonitorStatus]::Fail)
    $PolyMon.SetStatusMessage("Matrix server unreachable: $($_.Exception.Message)")
    return
}

# Check 2: Get health stats
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health.json" -TimeoutSec 15
} catch {
    $PolyMon.SetStatus([PolyMon.MonitorStatus]::Fail)
    $PolyMon.SetStatusMessage("Health endpoint unreachable: $($_.Exception.Message)")
    return
}

# Set counters for trending
$PolyMon.SetCounter("DiskPct", $health.disk_pct)
$PolyMon.SetCounter("DiskFreeGB", $health.disk_free_gb)
$PolyMon.SetCounter("BackupAgeHrs", $health.last_backup_age_hours)

# Check health.json freshness (if older than 15 min, cron may be broken)
$healthAge = (Get-Date).ToUniversalTime() - [datetime]::Parse($health.timestamp)
if ($healthAge.TotalMinutes -gt 15) {
    $PolyMon.SetStatus([PolyMon.MonitorStatus]::Warning)
    $PolyMon.SetStatusMessage("Health data is stale ($([int]$healthAge.TotalMinutes) min old)")
    return
}

# Evaluate thresholds
$status = [PolyMon.MonitorStatus]::OK
$messages = @()

# Disk checks
if ($health.disk_pct -gt 90) {
    $status = [PolyMon.MonitorStatus]::Fail
    $messages += "Disk critical: $($health.disk_pct)%"
} elseif ($health.disk_pct -gt 80) {
    if ($status -ne [PolyMon.MonitorStatus]::Fail) { $status = [PolyMon.MonitorStatus]::Warning }
    $messages += "Disk high: $($health.disk_pct)%"
}

# Container checks
if ($health.containers.conduit -ne "running") {
    $status = [PolyMon.MonitorStatus]::Fail
    $messages += "Conduit: $($health.containers.conduit)"
}
if ($health.containers.'mautrix-signal' -ne "running") {
    $status = [PolyMon.MonitorStatus]::Fail
    $messages += "mautrix-signal: $($health.containers.'mautrix-signal')"
}

# Backup freshness
if ($health.last_backup_age_hours -lt 0) {
    if ($status -ne [PolyMon.MonitorStatus]::Fail) { $status = [PolyMon.MonitorStatus]::Warning }
    $messages += "No backups found"
} elseif ($health.last_backup_age_hours -gt 48) {
    if ($status -ne [PolyMon.MonitorStatus]::Fail) { $status = [PolyMon.MonitorStatus]::Warning }
    $messages += "Backup stale: $($health.last_backup_age_hours)h ago"
}

# Set final status
if ($messages.Count -eq 0) {
    $messages += "All OK | Disk: $($health.disk_pct)% | Up: $($health.uptime_hours)h | Backup: $($health.last_backup_age_hours)h ago"
}

$PolyMon.SetStatus($status)
$PolyMon.SetStatusMessage($messages -join "; ")
