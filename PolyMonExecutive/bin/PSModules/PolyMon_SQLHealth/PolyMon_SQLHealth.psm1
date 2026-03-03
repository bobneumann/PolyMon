<#
.SYNOPSIS
    SQL Server health monitor for PolyMon.
.DESCRIPTION
    Connects to a SQL Server instance and evaluates a configurable set of health
    checks: agent jobs, backups, database health, drive space, and performance
    metrics. Designed to run inside a PolyMon PowerShell monitor.

    Enable checks with -Check* switch parameters. Severity of each alert is
    controlled by a matching -Severity parameter ("Warn" or "Fail").

    NOTE: TSM backup confirmation was removed from this version — it required
    reading a UNC-path log file and is too environment-specific for a general
    module.

.PARAMETER HostName
    SQL Server hostname. Required.

.PARAMETER InstanceName
    Named instance, e.g. "SQLEXPRESS". Omit or use "default" for default instance.

.PARAMETER CheckAgentService
    Alert if SQL Server Agent service is not running. Recommended — without Agent
    running, all job-based checks return silent false negatives.
.PARAMETER AgentServiceSeverity
    "Warn" or "Fail" (default: Fail)

.PARAMETER CheckDailyBackup
    Check that a daily full backup job succeeded within DailyBackupMaxDays.
.PARAMETER DailyBackupJobName
    Job name wildcard pattern. Default: "DBA Daily Full Backup*"
.PARAMETER DailyBackupSeverity
    "Warn" or "Fail" (default: Warn)
.PARAMETER DailyBackupMaxDays
    Maximum days since last successful run. Default: 1

.PARAMETER CheckWeeklyBackup / WeeklyBackupJobName / WeeklyBackupSeverity / WeeklyBackupMaxDays
    Same as daily backup, for weekly full backup job.

.PARAMETER CheckTranslogBackup
    Check that a transaction log backup job succeeded within TranslogMaxMinutes.
.PARAMETER TranslogJobName / TranslogSeverity / TranslogMaxMinutes
    Job name pattern, severity, and age threshold (minutes).

.PARAMETER CheckIntegrityJobs
    Check that a DBCC integrity job succeeded within IntegrityMaxDays.
.PARAMETER IntegrityJobName / IntegritySeverity / IntegrityMaxDays
    Job name pattern, severity, and age threshold (days).

.PARAMETER CheckExhaustiveBackup
    Verify every non-system database has a backup within ExhaustiveBackupMaxDays.
    Catches databases not covered by a named backup job.
.PARAMETER ExhaustiveBackupSeverity / ExhaustiveBackupMaxDays
    Severity and age threshold.
.PARAMETER ExhaustiveBackupIgnore
    Database names to skip. E.g. @("Staging","Scratch")

.PARAMETER CheckDBStatus
    Alert on databases in SUSPECT, RECOVERY_PENDING, EMERGENCY, or other
    abnormal states. Recommended — these are silent killers.
.PARAMETER DBStatusSeverity
    "Warn" or "Fail" (default: Fail)

.PARAMETER CheckRecoveryModel
    Alert on non-system databases not using Full recovery model.
.PARAMETER RecoveryModelSeverity
    "Warn" or "Fail" (default: Warn)
.PARAMETER ApprovedSimpleDBs
    Databases known to use Simple recovery intentionally. E.g. @("ReportStaging")

.PARAMETER CheckLogfileRatio
    Alert when a log file exceeds LogfileRatioMaxPct% of total database size.
    A bloated log file usually means either log backups aren't running or a long
    open transaction is preventing log truncation.
.PARAMETER LogfileRatioSeverity / LogfileRatioMaxPct
    Severity and threshold (percent).

.PARAMETER CheckDBFreespace
    Alert when datafile free space (pre-allocated space not yet used) drops below
    threshold. Does not measure drive space — see CheckDriveFreespace for that.
.PARAMETER DBFreespaceWarnPct / DBFreespaceFailPct
    Warn and fail thresholds (percent free within datafile).

.PARAMETER CheckDBsOnCDrive
    Alert if any database files are located on C:.

.PARAMETER CheckDriveFreespace
    Alert when host drive free space drops below threshold (via WMI).
.PARAMETER DriveFreespaceWarnPct / DriveFreespaceFailPct
    Warn and fail thresholds (percent free).

.PARAMETER CheckPLE
    Alert when Page Life Expectancy drops below threshold. PLE is the single
    best real-time memory health indicator for SQL Server.
.PARAMETER PLEWarnThreshold / PLEFailThreshold
    PLE thresholds in seconds. Defaults: 1000 / 500.
    Rule of thumb: expect ~1000s per 4GB of buffer pool RAM.

.PARAMETER CheckBlocking
    Alert when one or more sessions have been blocked longer than threshold.
    Records blocked session count and max wait time as counters.
.PARAMETER BlockingWarnSeconds / BlockingFailSeconds
    Block duration thresholds in seconds. Defaults: 30 / 120.

.PARAMETER CheckMemoryGrants
    Alert when memory grants pending > 0. A non-zero value means queries are
    queuing for workspace memory — a sign of memory pressure under load.
.PARAMETER MemoryGrantsSeverity
    "Warn" or "Fail" (default: Warn)

.PARAMETER CheckErrorLog
    Scan SQL error log for severity 17+ messages in the last ErrorLogMinutes.
    Catches corruption errors (823/824/825), out-of-memory, and fatal errors.
.PARAMETER ErrorLogMinutes
    Lookback window in minutes. Default: 60. Set to match your monitor interval.
.PARAMETER ErrorLogSeverity
    "Warn" or "Fail" (default: Warn)

.PARAMETER RecordUserCount
    Record total active connection count as a PolyMon counter.

.PARAMETER RecordBackupDuration
    Record duration of last full backup job (minutes) as a PolyMon counter.
    Only applies to jobs whose name contains "User" (UserDB backup convention).

.PARAMETER CheckSQLVersion
    Alert if SQL Server major version is below MinSQLVersion.
    Always records version string as a counter.
.PARAMETER MinSQLVersion
    Minimum acceptable major version. Default: 11 (SQL Server 2012).
    Use 15 for SQL 2019, 16 for SQL 2022.
.PARAMETER SQLVersionSeverity
    "Warn" or "Fail" (default: Warn)

.PARAMETER DetailLevel
    0 = problem items only in status text (default)
    1 = include OK items in status text (verbose)

.EXAMPLE
    # Minimal — just backups and drive space
    SQL_Overview -HostName "SQLPRD01" `
        -CheckAgentService -CheckDailyBackup -CheckDriveFreespace

.EXAMPLE
    # Full monitoring for an Epic application database server
    SQL_Overview -HostName "EPICPRD01" -InstanceName "EPIC" `
        -CheckAgentService `
        -CheckDailyBackup   -DailyBackupJobName "DBA Daily Full Backup*" `
        -CheckTranslogBackup -TranslogJobName "BackupUser.Logs*" -TranslogMaxMinutes 60 `
        -CheckIntegrityJobs  -IntegrityJobName "DBA Integrity*" -IntegrityMaxDays 14 `
        -CheckExhaustiveBackup -ExhaustiveBackupIgnore @("tempdb","Scratch") `
        -CheckDBStatus `
        -CheckRecoveryModel  -ApprovedSimpleDBs @("ReportCache") `
        -CheckLogfileRatio   -LogfileRatioMaxPct 40 `
        -CheckDriveFreespace `
        -CheckPLE `
        -CheckBlocking `
        -CheckMemoryGrants `
        -CheckErrorLog       -ErrorLogMinutes 60 `
        -RecordUserCount     -RecordBackupDuration
#>

function SQL_Overview {
    param(
        # ── Connection ────────────────────────────────────────────────────────
        [Parameter(Mandatory)][string] $HostName,
        [string] $InstanceName = "default",

        # ── SQL Agent service ─────────────────────────────────────────────────
        [switch] $CheckAgentService,
        [ValidateSet("Warn","Fail")][string] $AgentServiceSeverity = "Fail",

        # ── Daily full backup job ─────────────────────────────────────────────
        [switch] $CheckDailyBackup,
        [string] $DailyBackupJobName  = "DBA Daily Full Backup*",
        [ValidateSet("Warn","Fail")][string] $DailyBackupSeverity = "Warn",
        [int]    $DailyBackupMaxDays  = 1,

        # ── Weekly full backup job ────────────────────────────────────────────
        [switch] $CheckWeeklyBackup,
        [string] $WeeklyBackupJobName = "DBA Weekly Full Backup*",
        [ValidateSet("Warn","Fail")][string] $WeeklyBackupSeverity = "Warn",
        [int]    $WeeklyBackupMaxDays = 7,

        # ── Transaction log backup job ────────────────────────────────────────
        [switch] $CheckTranslogBackup,
        [string] $TranslogJobName     = "BackupUser.Logs*",
        [ValidateSet("Warn","Fail")][string] $TranslogSeverity = "Warn",
        [int]    $TranslogMaxMinutes  = 242,

        # ── Integrity check job ───────────────────────────────────────────────
        [switch] $CheckIntegrityJobs,
        [string] $IntegrityJobName    = "DBA Integrity*",
        [ValidateSet("Warn","Fail")][string] $IntegritySeverity = "Warn",
        [int]    $IntegrityMaxDays    = 14,

        # ── Per-database exhaustive backup check ──────────────────────────────
        [switch]   $CheckExhaustiveBackup,
        [ValidateSet("Warn","Fail")][string] $ExhaustiveBackupSeverity = "Warn",
        [int]      $ExhaustiveBackupMaxDays = 30,
        [string[]] $ExhaustiveBackupIgnore  = @(),

        # ── Database status (SUSPECT, RECOVERY_PENDING, etc.) ─────────────────
        [switch] $CheckDBStatus,
        [ValidateSet("Warn","Fail")][string] $DBStatusSeverity = "Fail",

        # ── Recovery model ────────────────────────────────────────────────────
        [switch]   $CheckRecoveryModel,
        [ValidateSet("Warn","Fail")][string] $RecoveryModelSeverity = "Warn",
        [string[]] $ApprovedSimpleDBs = @(),

        # ── Log file to database size ratio ───────────────────────────────────
        [switch] $CheckLogfileRatio,
        [ValidateSet("Warn","Fail")][string] $LogfileRatioSeverity = "Warn",
        [int]    $LogfileRatioMaxPct  = 50,

        # ── Database datafile free space ──────────────────────────────────────
        [switch] $CheckDBFreespace,
        [int]    $DBFreespaceWarnPct  = 10,
        [int]    $DBFreespaceFailPct  = 5,

        # ── Databases on C: drive ─────────────────────────────────────────────
        [switch] $CheckDBsOnCDrive,

        # ── Host drive free space (WMI) ───────────────────────────────────────
        [switch] $CheckDriveFreespace,
        [int]    $DriveFreespaceWarnPct = 10,
        [int]    $DriveFreespaceFailPct = 5,

        # ── Page Life Expectancy ──────────────────────────────────────────────
        [switch] $CheckPLE,
        [int]    $PLEWarnThreshold    = 1000,
        [int]    $PLEFailThreshold    = 500,

        # ── Blocking ──────────────────────────────────────────────────────────
        [switch] $CheckBlocking,
        [int]    $BlockingWarnSeconds = 30,
        [int]    $BlockingFailSeconds = 120,

        # ── Memory grants pending ─────────────────────────────────────────────
        [switch] $CheckMemoryGrants,
        [ValidateSet("Warn","Fail")][string] $MemoryGrantsSeverity = "Warn",

        # ── SQL error log scan ────────────────────────────────────────────────
        [switch] $CheckErrorLog,
        [int]    $ErrorLogMinutes     = 60,
        [ValidateSet("Warn","Fail")][string] $ErrorLogSeverity = "Warn",

        # ── Counters ──────────────────────────────────────────────────────────
        [switch] $RecordUserCount,
        [switch] $RecordBackupDuration,

        # ── SQL Server version ────────────────────────────────────────────────
        [switch] $CheckSQLVersion,
        [int]    $MinSQLVersion       = 11,
        [ValidateSet("Warn","Fail")][string] $SQLVersionSeverity = "Warn",

        # ── Output ────────────────────────────────────────────────────────────
        [int]    $DetailLevel         = 0
    )

    # ── PolyMon detection ─────────────────────────────────────────────────────
    $polymon = [bool]$Counters
    if ($polymon) { $Status.StatusText = "" }

    # ── State ─────────────────────────────────────────────────────────────────
    $script:errlvl = "OK"
    $alerts = [System.Collections.Generic.List[string]]::new()
    $sysDbs = @("master","model","msdb","tempdb")

    # Escalate severity — never downgrade (fail stays fail)
    function Set-Severity([string]$level) {
        if     ($level -eq "Fail" -and $script:errlvl -ne "fail") { $script:errlvl = "fail" }
        elseif ($level -eq "Warn" -and $script:errlvl -eq "OK"  ) { $script:errlvl = "warn" }
    }

    function Add-Counter([string]$name, [double]$value) {
        if ($script:polymon) { $Counters.Add($name, $value) }
    }

    # ── Connect via SMO ───────────────────────────────────────────────────────
    $instance = if ($InstanceName -eq "default") { $HostName } else { "$HostName\$InstanceName" }
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

    try {
        $s = New-Object Microsoft.SqlServer.Management.Smo.Server $instance
        # Force the connection now so we fail fast
        $null = $s.VersionMajor
    } catch {
        Set-Severity "Fail"
        $msg = "Cannot connect to ${instance}: $_"
        if ($polymon) { $Status.StatusID = 3; $Status.StatusText = $msg }
        else          { Write-Host "fail - $msg" }
        return
    }

    # Run a T-SQL query and return the first table
    function Invoke-Query([string]$sql) {
        try { ($s.ConnectionContext.ExecuteWithResults($sql)).Tables[0] } catch { $null }
    }

    # Run a T-SQL query and return a single scalar value
    function Invoke-Scalar([string]$sql) {
        try { $s.ConnectionContext.ExecuteScalar($sql) } catch { $null }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  SQL AGENT SERVICE
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckAgentService) {
        try   { $agentRunning = ($s.JobServer.Status -eq "Running") }
        catch { $agentRunning = $false }

        if (-not $agentRunning) {
            $alerts.Add("SQL Agent is NOT running (all job checks unreliable)")
            Set-Severity $AgentServiceSeverity
        } elseif ($DetailLevel -ge 1) {
            $alerts.Add("SQL Agent: Running")
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  AGENT JOBS  (daily backup / weekly backup / translog / integrity)
    # ═══════════════════════════════════════════════════════════════════════════
    $needJobs = $CheckDailyBackup -or $CheckWeeklyBackup -or
                $CheckTranslogBackup -or $CheckIntegrityJobs -or $RecordBackupDuration

    if ($needJobs) {
        $dailyCutoff    = [datetime]::Now.AddDays(-$DailyBackupMaxDays)
        $weeklyCutoff   = [datetime]::Now.AddDays(-$WeeklyBackupMaxDays)
        $translogCutoff = [datetime]::Now.AddMinutes(-$TranslogMaxMinutes)
        $integrityCutoff= [datetime]::Now.AddDays(-$IntegrityMaxDays)

        $dailyFound = $weeklyFound = $transFound = $intFound = $false
        $backupDurMin   = 0.0
        $backupDurLabel = ""

        foreach ($job in $s.JobServer.Jobs) {
            $isDaily     = $CheckDailyBackup    -and ($job.Name -like $DailyBackupJobName)  -and
                                                      ($job.Name -notlike $TranslogJobName)  -and
                                                      ($job.Name -notlike $WeeklyBackupJobName)
            $isWeekly    = $CheckWeeklyBackup   -and ($job.Name -like $WeeklyBackupJobName) -and
                                                      ($job.Name -notlike $TranslogJobName)  -and
                                                      ($job.Name -notlike $DailyBackupJobName)
            $isTranslog  = $CheckTranslogBackup -and ($job.Name -like $TranslogJobName)
            $isIntegrity = $CheckIntegrityJobs  -and ($job.Name -like $IntegrityJobName)

            # Skip jobs currently running — their LastRunDate reflects the previous run
            $running = ($job.CurrentRunStatus -eq "Executing")

            if ($isDaily) {
                $dailyFound = $true
                if (-not $running) {
                    $ok = ($job.LastRunOutcome -eq "Succeeded") -and ($job.LastRunDate -ge $dailyCutoff)
                    if (-not $ok) {
                        $alerts.Add("Daily backup '$($job.Name)': $($job.LastRunOutcome) on $($job.LastRunDate.ToString('MM/dd HH:mm'))")
                        Set-Severity $DailyBackupSeverity
                    } elseif ($DetailLevel -ge 1) {
                        $alerts.Add("Daily backup OK: $($job.Name) @ $($job.LastRunDate.ToString('MM/dd HH:mm'))")
                    }

                    # Capture duration of UserDB backup jobs for the counter
                    if ($RecordBackupDuration -and $job.Name -match "User") {
                        foreach ($entry in $job.EnumHistory()) {
                            if ($entry[9] -eq $job.LastRunDate -and $entry[4] -eq '(Job outcome)') {
                                $raw = [int]$entry[10]
                                $hh  = [int][Math]::Truncate($raw / 10000); $raw -= $hh * 10000
                                $mm  = [int][Math]::Truncate($raw / 100);   $raw -= $mm * 100
                                $backupDurMin   = [Math]::Round($hh * 60 + $mm + $raw / 60.0, 1)
                                $backupDurLabel = "$($job.Name) duration (min)"
                                break
                            }
                        }
                    }
                }
            }

            if ($isWeekly) {
                $weeklyFound = $true
                if (-not $running) {
                    $ok = ($job.LastRunOutcome -eq "Succeeded") -and ($job.LastRunDate -ge $weeklyCutoff)
                    if (-not $ok) {
                        $alerts.Add("Weekly backup '$($job.Name)': $($job.LastRunOutcome) on $($job.LastRunDate.ToString('MM/dd HH:mm'))")
                        Set-Severity $WeeklyBackupSeverity
                    } elseif ($DetailLevel -ge 1) {
                        $alerts.Add("Weekly backup OK: $($job.Name) @ $($job.LastRunDate.ToString('MM/dd HH:mm'))")
                    }
                }
            }

            if ($isTranslog) {
                $transFound = $true
                if (-not $running) {
                    $ok = ($job.LastRunOutcome -eq "Succeeded") -and ($job.LastRunDate -ge $translogCutoff)
                    if (-not $ok) {
                        $alerts.Add("Translog backup '$($job.Name)': $($job.LastRunOutcome) on $($job.LastRunDate.ToString('MM/dd HH:mm'))")
                        Set-Severity $TranslogSeverity
                    } elseif ($DetailLevel -ge 1) {
                        $alerts.Add("Translog OK: $($job.Name) @ $($job.LastRunDate.ToString('MM/dd HH:mm'))")
                    }
                }
            }

            if ($isIntegrity) {
                $intFound = $true
                if (-not $running) {
                    $ok = ($job.LastRunOutcome -eq "Succeeded") -and ($job.LastRunDate -ge $integrityCutoff)
                    if (-not $ok) {
                        $alerts.Add("Integrity '$($job.Name)': $($job.LastRunOutcome) on $($job.LastRunDate.ToString('MM/dd'))")
                        Set-Severity $IntegritySeverity
                    } elseif ($DetailLevel -ge 1) {
                        $alerts.Add("Integrity OK: $($job.Name) @ $($job.LastRunDate.ToString('MM/dd'))")
                    }
                }
            }
        }

        # Report any expected jobs that were not found at all
        if ($CheckDailyBackup    -and -not $dailyFound)  { $alerts.Add("Daily backup job not found (pattern: '$DailyBackupJobName')");   Set-Severity $DailyBackupSeverity  }
        if ($CheckWeeklyBackup   -and -not $weeklyFound) { $alerts.Add("Weekly backup job not found (pattern: '$WeeklyBackupJobName')"); Set-Severity $WeeklyBackupSeverity }
        if ($CheckTranslogBackup -and -not $transFound)  { $alerts.Add("Translog job not found (pattern: '$TranslogJobName')");          Set-Severity $TranslogSeverity     }
        if ($CheckIntegrityJobs  -and -not $intFound)    { $alerts.Add("Integrity job not found (pattern: '$IntegrityJobName')");        Set-Severity $IntegritySeverity    }

        if ($RecordBackupDuration -and $backupDurLabel) {
            Add-Counter $backupDurLabel $backupDurMin
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  DATABASE-LEVEL CHECKS
    # ═══════════════════════════════════════════════════════════════════════════
    $totalConnections = 0
    $exhaustiveFailed = [System.Collections.Generic.List[string]]::new()
    $exhaustiveCutoff = [datetime]::Now.AddDays(-$ExhaustiveBackupMaxDays)
    $newDBCutoff      = [datetime]::Now.AddDays(-2)   # skip databases created in last 2 days

    foreach ($db in $s.Databases) {
        # Skip mirrored secondaries and offline databases
        if ($db.MirroringStatus -eq "Synchronized" -or $db.Status -match "Offline") { continue }

        $isSystemDB = $sysDbs -contains $db.Name

        # ── Abnormal database status ───────────────────────────────────────────
        if ($CheckDBStatus -and $db.Status -notmatch "Normal") {
            $alerts.Add("DB '$($db.Name)': $($db.Status)")
            Set-Severity $DBStatusSeverity
        }

        # ── Recovery model ─────────────────────────────────────────────────────
        if ($CheckRecoveryModel -and -not $isSystemDB -and $ApprovedSimpleDBs -notcontains $db.Name) {
            if ($db.RecoveryModel -ne "Full") {
                $alerts.Add("DB '$($db.Name)' recovery model: $($db.RecoveryModel)")
                Set-Severity $RecoveryModelSeverity
            }
        }

        # ── Log file ratio ─────────────────────────────────────────────────────
        if ($CheckLogfileRatio -and -not $isSystemDB -and $db.Size -gt 0) {
            $totalLogMB  = ($db.LogFiles | Measure-Object -Property Size -Sum).Sum / 1KB
            $logRatioPct = [Math]::Round($totalLogMB / $db.Size * 100, 1)
            Add-Counter "Log ratio% $($db.Name)" $logRatioPct
            if ($logRatioPct -gt $LogfileRatioMaxPct) {
                $alerts.Add("DB '$($db.Name)' log/data ratio: ${logRatioPct}%")
                Set-Severity $LogfileRatioSeverity
            }
        }

        # ── Datafile free space ────────────────────────────────────────────────
        if ($CheckDBFreespace -and -not $isSystemDB -and $db.Size -gt 0) {
            $freePct = [Math]::Round($db.SpaceAvailable / 1KB / $db.Size * 100, 1)
            if ($freePct -lt $DBFreespaceWarnPct) {
                $alerts.Add("DB '$($db.Name)' free space: ${freePct}%")
                Add-Counter "DB free% $($db.Name)" $freePct
                if ($freePct -lt $DBFreespaceFailPct) { Set-Severity "Fail" }
                else                                   { Set-Severity "Warn" }
            } elseif ($DetailLevel -ge 1) {
                Add-Counter "DB free% $($db.Name)" $freePct
            }
        }

        # ── Databases on C: drive ──────────────────────────────────────────────
        if ($CheckDBsOnCDrive) {
            $drive = ($db.PrimaryFilePath -split ":")[0]
            if ($drive -ieq "C") {
                $alerts.Add("DB '$($db.Name)' files on C: drive")
                Set-Severity "Warn"
            }
        }

        # ── Exhaustive backup age check ────────────────────────────────────────
        if ($CheckExhaustiveBackup -and
            $db.Name -ne "tempdb" -and
            $ExhaustiveBackupIgnore -notcontains $db.Name -and
            $db.CreateDate -lt $newDBCutoff) {
            if ($db.LastBackupDate -lt $exhaustiveCutoff) {
                $exhaustiveFailed.Add($db.Name)
            }
        }

        # ── Connection count ───────────────────────────────────────────────────
        if ($RecordUserCount) {
            $totalConnections += $s.GetActiveDBConnectionCount($db.Name)
        }
    }

    # Report exhaustive backup results
    if ($CheckExhaustiveBackup) {
        if ($exhaustiveFailed.Count -gt 0) {
            $alerts.Add("No backup in ${ExhaustiveBackupMaxDays}d: $($exhaustiveFailed -join ', ')")
            Add-Counter "DBs missing backup" $exhaustiveFailed.Count
            Set-Severity $ExhaustiveBackupSeverity
        } elseif ($DetailLevel -ge 1) {
            $alerts.Add("All databases backed up within ${ExhaustiveBackupMaxDays}d")
        }
    }

    if ($RecordUserCount) { Add-Counter "Total connections" $totalConnections }

    # ═══════════════════════════════════════════════════════════════════════════
    #  DRIVE FREE SPACE  (WMI)
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckDriveFreespace) {
        $drives = Get-WmiObject -ComputerName $HostName Win32_LogicalDisk `
                      -ErrorAction SilentlyContinue |
                  Where-Object { $_.DriveType -eq 3 -and $_.Size -gt 0 }

        if (-not $drives) {
            $alerts.Add("Drive freespace: WMI query returned no results")
            Set-Severity "Warn"
        } else {
            foreach ($drive in $drives) {
                $freePct = [Math]::Round($drive.FreeSpace / $drive.Size * 100, 1)
                Add-Counter "Drive free% $($drive.DeviceID)" $freePct
                if ($freePct -lt $DriveFreespaceWarnPct) {
                    $alerts.Add("Drive $($drive.DeviceID) free: ${freePct}%")
                    if ($freePct -lt $DriveFreespaceFailPct) { Set-Severity "Fail" }
                    else                                       { Set-Severity "Warn" }
                } elseif ($DetailLevel -ge 1) {
                    $alerts.Add("Drive $($drive.DeviceID) free: ${freePct}% OK")
                }
            }
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  PAGE LIFE EXPECTANCY
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckPLE) {
        $ple = Invoke-Scalar @"
SELECT cntr_value
FROM   sys.dm_os_performance_counters
WHERE  counter_name = 'Page life expectancy'
  AND  object_name  LIKE '%Buffer Manager%'
"@
        if ($null -ne $ple) {
            $ple = [int]$ple
            Add-Counter "Page life expectancy (sec)" $ple
            if ($ple -lt $PLEFailThreshold) {
                $alerts.Add("Page Life Expectancy: ${ple}s (fail < ${PLEFailThreshold}s)")
                Set-Severity "Fail"
            } elseif ($ple -lt $PLEWarnThreshold) {
                $alerts.Add("Page Life Expectancy: ${ple}s (warn < ${PLEWarnThreshold}s)")
                Set-Severity "Warn"
            } elseif ($DetailLevel -ge 1) {
                $alerts.Add("Page Life Expectancy: ${ple}s OK")
            }
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  BLOCKING
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckBlocking) {
        $blocked = Invoke-Query @"
SELECT r.session_id,
       r.blocking_session_id,
       DATEDIFF(SECOND, r.start_time, GETDATE()) AS wait_sec,
       LEFT(ISNULL(t.text, ''), 80)              AS query_snippet
FROM   sys.dm_exec_requests r
CROSS  APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE  r.blocking_session_id > 0
  AND  DATEDIFF(SECOND, r.start_time, GETDATE()) >= $BlockingWarnSeconds
ORDER  BY wait_sec DESC
"@
        if ($blocked -and $blocked.Rows.Count -gt 0) {
            $maxWait    = ($blocked.Rows | Measure-Object -Property wait_sec -Maximum).Maximum
            $blockCount = $blocked.Rows.Count
            $alerts.Add("Blocking: $blockCount session(s) waiting, max ${maxWait}s")
            Add-Counter "Blocked sessions"       $blockCount
            Add-Counter "Max block wait (sec)"   $maxWait
            if ($maxWait -ge $BlockingFailSeconds) { Set-Severity "Fail" }
            else                                    { Set-Severity "Warn" }
        } else {
            Add-Counter "Blocked sessions" 0
            if ($DetailLevel -ge 1) { $alerts.Add("Blocking: none") }
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  MEMORY GRANTS PENDING
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckMemoryGrants) {
        $grants = Invoke-Scalar @"
SELECT cntr_value
FROM   sys.dm_os_performance_counters
WHERE  counter_name = 'Memory Grants Pending'
  AND  object_name  LIKE '%Memory Manager%'
"@
        if ($null -ne $grants) {
            $grants = [int]$grants
            Add-Counter "Memory grants pending" $grants
            if ($grants -gt 0) {
                $alerts.Add("Memory grants pending: $grants")
                Set-Severity $MemoryGrantsSeverity
            } elseif ($DetailLevel -ge 1) {
                $alerts.Add("Memory grants pending: 0 OK")
            }
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  ERROR LOG SCAN  (severity 17+)
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckErrorLog) {
        $startTime = [datetime]::Now.AddMinutes(-$ErrorLogMinutes).ToString("yyyy-MM-dd HH:mm:ss")
        # xp_readerrorlog args: archive#, log type (1=SQL), search1, search2, start, end, sort
        $errRows = Invoke-Query "EXEC xp_readerrorlog 0, 1, NULL, NULL, '$startTime', NULL, 'DESC'"

        if ($errRows -and $errRows.Rows.Count -gt 0) {
            # SQL error log embeds severity in the format: "Error: NNN, Severity: NN, State: N"
            $severeErrors = @($errRows.Rows | Where-Object {
                $_.Text -imatch "Severity:\s*(1[7-9]|2[0-4])"
            })
            if ($severeErrors.Count -gt 0) {
                $sample = $severeErrors[0].Text
                if ($sample.Length -gt 100) { $sample = $sample.Substring(0, 100) + "..." }
                $alerts.Add("SQL error log: $($severeErrors.Count) sev17+ error(s) in last ${ErrorLogMinutes}min - e.g.: $sample")
                Add-Counter "Error log hits (sev17+)" $severeErrors.Count
                Set-Severity $ErrorLogSeverity
            } else {
                Add-Counter "Error log hits (sev17+)" 0
                if ($DetailLevel -ge 1) { $alerts.Add("Error log: no severity 17+ in last ${ErrorLogMinutes}min") }
            }
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  SQL SERVER VERSION
    # ═══════════════════════════════════════════════════════════════════════════
    if ($CheckSQLVersion) {
        $major = $s.VersionMajor
        $versionNames = @{
            7="SQL Server 7";      8="SQL Server 2000";    9="SQL Server 2005"
            10="SQL Server 2008";  11="SQL Server 2012";   12="SQL Server 2014"
            13="SQL Server 2016";  14="SQL Server 2017";   15="SQL Server 2019"
            16="SQL Server 2022"
        }
        $name    = if ($versionNames.ContainsKey($major)) { $versionNames[$major] } else { "SQL Server v$major" }
        $fullVer = "$name ($($s.VersionString))"
        Add-Counter "SQL major version" $major

        if ($major -lt $MinSQLVersion) {
            $minName = if ($versionNames.ContainsKey($MinSQLVersion)) { $versionNames[$MinSQLVersion] } else { "v$MinSQLVersion" }
            $alerts.Add("SQL version below minimum ($minName): $fullVer")
            Set-Severity $SQLVersionSeverity
        } elseif ($DetailLevel -ge 1) {
            $alerts.Add("SQL version: $fullVer")
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #  OUTPUT
    # ═══════════════════════════════════════════════════════════════════════════
    $statusText = if ($alerts.Count -gt 0) { $alerts -join "; " } else { "OK" }

    if ($polymon) {
        $Status.StatusID = switch ($script:errlvl) {
            "fail"  { 3 }
            "warn"  { 2 }
            default { 1 }
        }
        $Status.StatusText = $statusText
    } else {
        Write-Host "$($script:errlvl.ToUpper()) - $statusText"
    }
}
