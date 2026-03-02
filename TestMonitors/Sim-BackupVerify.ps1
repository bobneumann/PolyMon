<#
.SYNOPSIS
    Simulated backup verification check. ~3-6 seconds.
    Mimics a monitor that walks backup manifests and verifies recency + size.
    Deliberately slow — this is the one that was dominating the sequential cycle.
    Warns if any backup > 26 hours old, fails if > 48 hours or size looks wrong.
#>

$polymon = if ($Counters) { $true } else { $false }

# Simulate walking backup files or querying TSM (3000-6000ms)
$elapsed_ms = Get-Random -Minimum 3000 -Maximum 6200
Start-Sleep -Milliseconds $elapsed_ms

# Hours since last full backup (normally 6-22, occasionally drifts)
$drift = if ((Get-Random -Minimum 1 -Maximum 8) -eq 1) { Get-Random -Minimum 20 -Maximum 36 } else { 0 }
$last_full_hours = Get-Random -Minimum 5 -Maximum 22
$last_full_hours += $drift

# Hours since last log backup (normally 0-2)
$last_log_hours = [Math]::Round((Get-Random -Minimum 0 -Maximum 2) + (Get-Random -Minimum 0 -Maximum 9) / 10.0, 1)

# Backup size GB (should be consistent; flag if < 80% of baseline)
$baseline_gb   = 142.0
$size_variance = (Get-Random -Minimum -15 -Maximum 8)
$backup_size_gb = [Math]::Round($baseline_gb + $size_variance, 1)

# Backup duration minutes
$backup_min = Get-Random -Minimum 28 -Maximum 95

# Verify pass (normally true; occasionally a verify failure)
$verify_ok = if ((Get-Random -Minimum 1 -Maximum 25) -eq 1) { 0 } else { 1 }

# Determine status
$status_id   = 1
$status_text = "OK"
$small_backup = $backup_size_gb -lt ($baseline_gb * 0.80)

if ($last_full_hours -gt 48 -or $verify_ok -eq 0 -or $small_backup) {
    $status_id   = 3
    $reason = if ($verify_ok -eq 0) { "verify FAILED" } `
              elseif ($small_backup) { "backup too small (${backup_size_gb}GB vs expected ${baseline_gb}GB)" } `
              else { "full backup ${last_full_hours}h old" }
    $status_text = "FAIL - $reason"
} elseif ($last_full_hours -gt 26 -or $last_log_hours -gt 3) {
    $status_id   = 2
    $status_text = "WARN - Full=${last_full_hours}h ago, log=${last_log_hours}h ago"
} else {
    $status_text = "OK - Full=${last_full_hours}h ago, ${backup_size_gb}GB, ${backup_min}min"
}

if ($polymon) {
    $Status.StatusID   = $status_id
    $Status.StatusText = $status_text
    $Counters.Add("last_full_hours",  $last_full_hours)
    $Counters.Add("last_log_hours",   $last_log_hours)
    $Counters.Add("backup_size_gb",   $backup_size_gb)
    $Counters.Add("backup_min",       $backup_min)
    $Counters.Add("verify_ok",        $verify_ok)
} else {
    Write-Host "Status:           $status_text"
    Write-Host "last_full_hours:  $last_full_hours"
    Write-Host "last_log_hours:   $last_log_hours"
    Write-Host "backup_size_gb:   $backup_size_gb"
    Write-Host "backup_min:       $backup_min"
    Write-Host "verify_ok:        $verify_ok"
}
