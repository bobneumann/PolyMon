# Matrix/Signal Bridge Health Monitor
# PolyMon PowerShell Monitor — paste into a new PowerShell monitor definition
# Checks: server alive, disk usage, container status, backup freshness,
#         and end-to-end Matrix message send
# Works both inside PolyMon and standalone in PowerShell ISE

$BaseUrl    = "https://matrix.yourdomain.com"       # <-- Change to your Matrix homeserver URL
$MatrixToken = "your-access-token-here"             # <-- Matrix access token (Bearer token)
$TestRoomId  = "!your-test-room-id:yourdomain.com"  # <-- Room ID for end-to-end send test

##########Script Contents Below######################

if($Counters){$polymon = 1}else{$polymon = 0}
$errlvl = "OK"
$Counter = @()
$messages = @()

###########"Display Data" function#####################
function display_data {
    $displaymessage = if ($messages.Count -eq 0) {
        "All OK | Disk: $($health.disk_pct)% | Up: $($health.uptime_hours)h | Backup: $($health.last_backup_age_hours)h ago | Bridge: $($health.bridge_age_min)m ago"
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
if ($health.bridge_age_min -ge 0) {
    $Counter += ,@('BridgeAgeMin', $health.bridge_age_min)
}

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

# Bridge delivery check (did mautrix-signal actually deliver to Signal recently?)
if ($health.bridge_age_min -lt 0) {
    if ($errlvl -ne "fail") { $errlvl = "warn" }
    $messages += "No bridge deliveries found in last 24h"
} elseif ($health.bridge_age_min -gt 30) {
    if ($errlvl -ne "fail") { $errlvl = "warn" }
    $messages += "Bridge delivery stale ($($health.bridge_age_min) min ago)"
}

# Check 3: End-to-end Matrix message send
# Sends a silent heartbeat message to a test room, proving auth + Conduit + room are working
try {
    $txnId = [guid]::NewGuid().ToString()
    $sendUrl = "$BaseUrl/_matrix/client/v3/rooms/$([Uri]::EscapeDataString($TestRoomId))/send/m.room.message/$txnId"
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss UTC")
    $body = @{
        msgtype = "m.notice"
        body    = "health check heartbeat $timestamp"
    } | ConvertTo-Json -Compress
    $headers = @{ Authorization = "Bearer $MatrixToken" }
    $sendResult = Invoke-RestMethod -Uri $sendUrl -Method Put -ContentType "application/json" -Body $body -Headers $headers -TimeoutSec 15
    if (-not $sendResult.event_id) {
        throw "No event_id returned"
    }
} catch {
    $errlvl = "fail"
    $messages += "Matrix send failed: $($_.Exception.Message)"
}

display_data
