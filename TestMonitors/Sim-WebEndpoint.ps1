<#
.SYNOPSIS
    Simulated web endpoint health check. ~1-3 seconds.
    Mimics a monitor that hits an HTTP endpoint and measures response time.
    Warns if response > 2000ms, fails if > 4000ms or error_rate > 5%.
#>

$polymon = if ($Counters) { $true } else { $false }

# Simulate network round-trip variance (1000-3000ms)
$base_ms   = 1200
$jitter_ms = Get-Random -Minimum -600 -Maximum 800
$response_ms = [Math]::Max(100, $base_ms + $jitter_ms)
Start-Sleep -Milliseconds $response_ms

# Simulate active sessions (20-80, slowly drifts)
$active_sessions = Get-Random -Minimum 22 -Maximum 74

# Simulate error rate (0-3%, occasionally spikes)
$spike = if ((Get-Random -Minimum 1 -Maximum 20) -eq 1) { Get-Random -Minimum 4 -Maximum 9 } else { 0 }
$error_rate = [Math]::Round((Get-Random -Minimum 0 -Maximum 3) + $spike, 1)

# Simulate throughput (requests/sec)
$requests_per_sec = Get-Random -Minimum 85 -Maximum 310

# Determine status
$status_id   = 1
$status_text = "OK"
if ($response_ms -gt 4000 -or $error_rate -gt 5) {
    $status_id   = 3
    $status_text = "FAIL - Response ${response_ms}ms, error rate ${error_rate}%"
} elseif ($response_ms -gt 2000 -or $error_rate -gt 2) {
    $status_id   = 2
    $status_text = "WARN - Response ${response_ms}ms, error rate ${error_rate}%"
} else {
    $status_text = "OK - Response ${response_ms}ms, ${active_sessions} sessions"
}

if ($polymon) {
    $Status.StatusID   = $status_id
    $Status.StatusText = $status_text
    $Counters.Add("response_ms",       $response_ms)
    $Counters.Add("active_sessions",   $active_sessions)
    $Counters.Add("error_rate_pct",    $error_rate)
    $Counters.Add("requests_per_sec",  $requests_per_sec)
} else {
    Write-Host "Status:          $status_text"
    Write-Host "response_ms:     $response_ms"
    Write-Host "active_sessions: $active_sessions"
    Write-Host "error_rate_pct:  $error_rate"
    Write-Host "requests_per_sec:$requests_per_sec"
}
