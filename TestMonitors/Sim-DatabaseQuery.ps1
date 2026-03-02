<#
.SYNOPSIS
    Simulated database query performance check. ~2-5 seconds.
    Mimics a monitor that runs a diagnostic query and checks key SQL health metrics.
    Warns on slow queries or low PLE, fails on blocking or very low PLE.
#>

$polymon = if ($Counters) { $true } else { $false }

# Simulate a more expensive SQL DMV query (2000-5000ms)
$query_ms = Get-Random -Minimum 1800 -Maximum 5200
Start-Sleep -Milliseconds $query_ms

# Page Life Expectancy: healthy is > 300, warn < 300, fail < 100
$ple = Get-Random -Minimum 180 -Maximum 950
# Occasionally simulate a PLE dip
if ((Get-Random -Minimum 1 -Maximum 15) -eq 1) { $ple = Get-Random -Minimum 60 -Maximum 150 }

# Active blocking chains (should be 0; occasionally 1-2)
$blocking_chains = if ((Get-Random -Minimum 1 -Maximum 12) -eq 1) { Get-Random -Minimum 1 -Maximum 3 } else { 0 }

# Buffer cache hit ratio (healthy > 99%)
$cache_hit_pct = [Math]::Round(97 + (Get-Random -Minimum 0 -Maximum 30) / 10.0, 1)

# Log used % on primary filegroup
$log_used_pct = Get-Random -Minimum 8 -Maximum 62

# Determine status
$status_id   = 1
$status_text = "OK"
if ($ple -lt 100 -or $blocking_chains -gt 1) {
    $status_id   = 3
    $status_text = "FAIL - PLE=${ple}, blocking=${blocking_chains}"
} elseif ($ple -lt 300 -or $blocking_chains -gt 0 -or $log_used_pct -gt 75) {
    $status_id   = 2
    $status_text = "WARN - PLE=${ple}, blocking=${blocking_chains}, log=${log_used_pct}%"
} else {
    $status_text = "OK - PLE=${ple}, cache=${cache_hit_pct}%, query=${query_ms}ms"
}

if ($polymon) {
    $Status.StatusID   = $status_id
    $Status.StatusText = $status_text
    $Counters.Add("query_ms",           $query_ms)
    $Counters.Add("ple",                $ple)
    $Counters.Add("blocking_chains",    $blocking_chains)
    $Counters.Add("cache_hit_pct",      $cache_hit_pct)
    $Counters.Add("log_used_pct",       $log_used_pct)
} else {
    Write-Host "Status:          $status_text"
    Write-Host "query_ms:        $query_ms"
    Write-Host "ple:             $ple"
    Write-Host "blocking_chains: $blocking_chains"
    Write-Host "cache_hit_pct:   $cache_hit_pct"
    Write-Host "log_used_pct:    $log_used_pct"
}
