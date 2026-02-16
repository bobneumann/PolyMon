# Matrix/Signal Bridge Health Monitor
# PolyMon PowerShell Monitor — paste into a new PowerShell monitor definition
# Checks: server alive, disk usage, container status, backup freshness
# Works both inside PolyMon and standalone in PowerShell ISE

$BaseUrl = "https://matrix.yourdomain.com"          # <-- Change to your Matrix homeserver URL

##########Script Contents Below######################

if($Counters){$polymon = 1}else{$polymon = 0}
$errlvl = "OK"
$Counter = @()
$messages = @()

###########"Display Data" function#####################
function display_data {
    $displaymessage = if ($messages.Count -eq 0) {
        "All OK | Disk: $($health.disk_pct)% | Up: $($health.uptime_hours)h | Backup: $($health.last_backup_age_hours)h ago"
    } else {
        $messages -join "; "
    }
    if ($polymon -eq 1) {
        switch ($errlvl) {
            "warn" { $Status.StatusID = 2 }
            "fail" { $Status.StatusID = 3 }
            default { $Status.StatusID = 1 }
        }
        $Status.StatusText = $displaymessage
        if ($Counter.length -gt 1) {
            $Counter = $Counter | select -uniq
            foreach ($count in $Counter) { $Counters.Add($count[0], $count[1]) }
        }
    } else {
        "$errlvl $displaymessage"
        foreach ($count in $Counter) { "  Counter: $($count[0]) = $($count[1])" }
    }
    break
}

# Check 1: Is the Matrix server responding?
try {
    $versions = Invoke-RestMethod -Uri "$BaseUrl/_matrix/client/versions" -TimeoutSec 15
    if (-not $versions.versions) {
        throw "Unexpected response from Matrix server"
    }
} catch {
    $errlvl = "fail"
    $messages += "Matrix server unreachable: $($_.Exception.Message)"
    display_data
}

# Check 2: Get health stats
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health.json" -TimeoutSec 15
} catch {
    $errlvl = "fail"
    $messages += "Health endpoint unreachable: $($_.Exception.Message)"
    display_data
}

# Set counters for trending
$Counter += ,@('DiskPct', $health.disk_pct)
$Counter += ,@('DiskFreeGB', $health.disk_free_gb)
$Counter += ,@('BackupAgeHrs', $health.last_backup_age_hours)

# Check health.json freshness (if older than 15 min, cron may be broken)
$healthAge = (Get-Date).ToUniversalTime() - ([datetime]::Parse($health.timestamp)).ToUniversalTime()
if ($healthAge.TotalMinutes -gt 15) {
    if ($errlvl -ne "fail") { $errlvl = "warn" }
    $messages += "Health data stale ($([int]$healthAge.TotalMinutes) min old)"
}

# Disk checks
if ($health.disk_pct -gt 90) {
    $errlvl = "fail"
    $messages += "Disk critical: $($health.disk_pct)%"
} elseif ($health.disk_pct -gt 80) {
    if ($errlvl -ne "fail") { $errlvl = "warn" }
    $messages += "Disk high: $($health.disk_pct)%"
}

# Container checks
if ($health.containers.conduit -ne "running") {
    $errlvl = "fail"
    $messages += "Conduit: $($health.containers.conduit)"
}
if ($health.containers.'mautrix-signal' -ne "running") {
    $errlvl = "fail"
    $messages += "mautrix-signal: $($health.containers.'mautrix-signal')"
}

# Backup freshness
if ($health.last_backup_age_hours -lt 0) {
    if ($errlvl -ne "fail") { $errlvl = "warn" }
    $messages += "No backups found"
} elseif ($health.last_backup_age_hours -gt 48) {
    if ($errlvl -ne "fail") { $errlvl = "warn" }
    $messages += "Backup stale: $($health.last_backup_age_hours)h ago"
}

display_data
