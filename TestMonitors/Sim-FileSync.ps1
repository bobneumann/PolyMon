<#
.SYNOPSIS
    Simulated file synchronization monitor. ~0.4-1.5 seconds.
    Mimics checking rsync/robocopy job recency and pending file counts.
    Fast monitor — good contrast against the slower DB/web ones in parallel.
    Warns if last sync > 10 min ago, fails if > 20 min.
#>

$polymon = if ($Counters) { $true } else { $false }

# Fast SSH-like check (400-1500ms)
$elapsed_ms = Get-Random -Minimum 400 -Maximum 1500
Start-Sleep -Milliseconds $elapsed_ms

# Minutes since last successful sync (0-8 normally, occasional delay)
$delay_spike = if ((Get-Random -Minimum 1 -Maximum 10) -eq 1) { Get-Random -Minimum 12 -Maximum 25 } else { 0 }
$last_sync_min = Get-Random -Minimum 1 -Maximum 8
$last_sync_min += $delay_spike

# Files pending in queue
$files_pending = if ($last_sync_min -gt 10) { Get-Random -Minimum 40 -Maximum 200 } else { Get-Random -Minimum 0 -Maximum 8 }

# Transfer rate KB/s (0 if not currently syncing)
$transfer_kbps = if ($files_pending -gt 0) { Get-Random -Minimum 800 -Maximum 8500 } else { 0 }

# Error count in last sync window
$sync_errors = if ((Get-Random -Minimum 1 -Maximum 20) -eq 1) { Get-Random -Minimum 1 -Maximum 4 } else { 0 }

# Determine status
$status_id   = 1
$status_text = "OK"
if ($last_sync_min -gt 20 -or $sync_errors -gt 2) {
    $status_id   = 3
    $status_text = "FAIL - Last sync ${last_sync_min} min ago, ${sync_errors} errors"
} elseif ($last_sync_min -gt 10 -or $sync_errors -gt 0) {
    $status_id   = 2
    $status_text = "WARN - Last sync ${last_sync_min} min ago, ${files_pending} files pending"
} else {
    $status_text = "OK - Last sync ${last_sync_min} min ago, ${files_pending} pending"
}

if ($polymon) {
    $Status.StatusID   = $status_id
    $Status.StatusText = $status_text
    $Counters.Add("last_sync_min",   $last_sync_min)
    $Counters.Add("files_pending",   $files_pending)
    $Counters.Add("transfer_kbps",   $transfer_kbps)
    $Counters.Add("sync_errors",     $sync_errors)
} else {
    Write-Host "Status:          $status_text"
    Write-Host "last_sync_min:   $last_sync_min"
    Write-Host "files_pending:   $files_pending"
    Write-Host "transfer_kbps:   $transfer_kbps"
    Write-Host "sync_errors:     $sync_errors"
}
