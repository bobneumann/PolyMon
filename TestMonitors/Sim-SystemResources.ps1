<#
.SYNOPSIS
    Simulated system resource monitor. ~0.3-0.8 seconds.
    Mimics WMI/SSH checks for CPU, memory, and disk on an app server.
    The fastest monitor in the set — good for contrast.
    Warns on CPU > 75% or memory > 85%, fails on CPU > 90% or memory > 95%.
#>

$polymon = if ($Counters) { $true } else { $false }

# Quick local WMI-style query (300-800ms)
$elapsed_ms = Get-Random -Minimum 300 -Maximum 800
Start-Sleep -Milliseconds $elapsed_ms

# CPU % — normally 15-55%, occasional spike
$cpu_spike = if ((Get-Random -Minimum 1 -Maximum 8) -eq 1) { Get-Random -Minimum 35 -Maximum 55 } else { 0 }
$cpu_pct = [Math]::Min(100, (Get-Random -Minimum 12 -Maximum 52) + $cpu_spike)

# Memory % — slowly climbs over time (no leak simulation, just variation)
$mem_pct = Get-Random -Minimum 48 -Maximum 82

# Disk free GB on C: (stable, slowly decreasing — set range tighter)
$disk_free_gb = [Math]::Round((Get-Random -Minimum 42 -Maximum 78) + (Get-Random -Minimum 0 -Maximum 9) / 10.0, 1)

# CPU run queue (healthy 0-2, warn 3-5, fail > 5)
$run_queue = if ($cpu_pct -gt 75) { Get-Random -Minimum 2 -Maximum 7 } else { Get-Random -Minimum 0 -Maximum 2 }

# Network utilization %
$net_util_pct = Get-Random -Minimum 2 -Maximum 28

# Determine status
$status_id   = 1
$status_text = "OK"
if ($cpu_pct -gt 90 -or $mem_pct -gt 95 -or $run_queue -gt 5) {
    $status_id   = 3
    $status_text = "FAIL - CPU=${cpu_pct}%, Mem=${mem_pct}%, Queue=${run_queue}"
} elseif ($cpu_pct -gt 75 -or $mem_pct -gt 85 -or $run_queue -gt 2) {
    $status_id   = 2
    $status_text = "WARN - CPU=${cpu_pct}%, Mem=${mem_pct}%, Queue=${run_queue}"
} else {
    $status_text = "OK - CPU=${cpu_pct}%, Mem=${mem_pct}%, Disk free=${disk_free_gb}GB"
}

if ($polymon) {
    $Status.StatusID   = $status_id
    $Status.StatusText = $status_text
    $Counters.Add("cpu_pct",        $cpu_pct)
    $Counters.Add("mem_pct",        $mem_pct)
    $Counters.Add("disk_free_gb",   $disk_free_gb)
    $Counters.Add("run_queue",      $run_queue)
    $Counters.Add("net_util_pct",   $net_util_pct)
} else {
    Write-Host "Status:          $status_text"
    Write-Host "cpu_pct:         $cpu_pct"
    Write-Host "mem_pct:         $mem_pct"
    Write-Host "disk_free_gb:    $disk_free_gb"
    Write-Host "run_queue:       $run_queue"
    Write-Host "net_util_pct:    $net_util_pct"
}
